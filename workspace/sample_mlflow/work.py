# Databricks notebook source
# MAGIC %md
# MAGIC # MLflow
# MAGIC 機械学習モデルの開発から本番デプロイまでのワークフローを管理するツール。ローカルでも使用できるが、 Databricks では UI が統合された形で使用できる。主に以下5機能が提供される。
# MAGIC
# MAGIC * Tracking:  
# MAGIC   作成したモデルやメトリクスをログへ記録する機能を提供。各ハイパーパラメータのモデルをメトリクスと共に記録・管理することでモデルのチューニングを支援する。
# MAGIC * Project:  
# MAGIC   モデル開発周りの訓練やデータ前処理用のコードを再利用・再現可能な方法でパッケージングする仕組みを提供 (Databricks 上で使うメリットが見出だせないため触れていません)
# MAGIC * Model:  
# MAGIC   機械学習モデルをパッケージ化するための標準形式を提供。モデルを推論用の共通インターフェイスでラップし、サービング時にモデルごとの違いを吸収
# MAGIC * Registry:  
# MAGIC   一元化されたモデルストアを提供。モデルのバージョン管理やタグ付けなど、モデルのライフサイクル管理を支援する。
# MAGIC * Serving:  
# MAGIC   さまざまなターゲットにモデルをデプロイするための簡単なツールセットを提供
# MAGIC
# MAGIC ## 参考URL
# MAGIC
# MAGIC * MLflow 機能概要: https://ktksq.hatenablog.com/entry/mlflow-model-registry
# MAGIC * MLflow on Databricks: https://docs.databricks.com/ja/mlflow/tracking.html

# COMMAND ----------

# MAGIC %md
# MAGIC # 事前準備

# COMMAND ----------

import numpy as np
import pickle
import sklearn.datasets
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, OneHotEncoder, LabelEncoder
from sklearn.pipeline import make_pipeline

# COMMAND ----------

iris = sklearn.datasets.load_iris()
data, target = iris["data"], iris["target"]

# COMMAND ----------

WORKSPACE_CATALOG = "..."

# COMMAND ----------

# MAGIC %md
# MAGIC # Tracking

# COMMAND ----------

# MAGIC %md
# MAGIC ## 訓練結果を記録
# MAGIC with mlflow.start_run() の中で mlflow.log を用いて訓練時の情報を記録する。
# MAGIC
# MAGIC `mlflow.(フレーバー).log_model()` を用いて対象を MLflow 標準の Model 形式で記録できる。有名なライブラリへは標準 Model 形式で記録する処理がフレーバーとして標準提供されている。
# MAGIC
# MAGIC * 概要: https://mlflow.org/docs/latest/tracking/tracking-api.html
# MAGIC * Scikit-Learn Flavor: https://mlflow.org/docs/latest/models.html#scikit-learn-sklearn

# COMMAND ----------

import mlflow

MAIL_ADDRESS = "..."

# Notebook Experiments
# mlflow.set_experiment(f"/Users/{MAIL_ADDRESS}/sample-ml/work")

# Workspace Experiments
# mlflow.set_experiment("/Users/{MAIL_ADDRESS}/sample-ml/experiment-sample")

# 自動ロギングを無効化
# 参考URL: https://mlflow.org/docs/latest/tracking/autolog.html
mlflow.sklearn.autolog(disable=True)

# COMMAND ----------

x_train, x_test, y_train, y_test = train_test_split(data, target)

model = make_pipeline(StandardScaler(), RandomForestClassifier())
ohe_trans = OneHotEncoder(sparse_output=False)

y_train_preped = ohe_trans.fit_transform(y_train[:,np.newaxis])
y_test_preped = ohe_trans.transform(y_test[:,np.newaxis])
model.fit(x_train, y_train_preped)

with mlflow.start_run():
    # 説明変数用
    signature = mlflow.models.infer_signature(x_train, y_train_preped)
    model_info_1 = mlflow.sklearn.log_model(model, "model", signature=signature, input_example=x_train[:10])
    mlflow.log_params(model.get_params())
    mlflow.log_input(mlflow.data.from_numpy(x_train, source="iris"), context="Train")
    mlflow.log_metric("score", model.score(x_test, y_test_preped))

    # 目的変数用
    signature = mlflow.models.infer_signature(y_train, y_train_preped)
    model_info_2 = mlflow.sklearn.log_model(ohe_trans, "post", signature=signature, input_example=y_train[:10])

    mlflow.set_tag("sample-tag", "hello MLflow")


# COMMAND ----------

# MAGIC %md
# MAGIC ## カスタムモデル
# MAGIC フレーバーが無い独自モデルも記録可能。  
# MAGIC 関数ベースモデルとクラスベースのモデルが有る。ここではクラスベースで実行する。
# MAGIC
# MAGIC * 概要:  
# MAGIC   https://mlflow.org/docs/latest/python_api/mlflow.pyfunc.html#pyfunc-create-custom
# MAGIC * クラスベースモデルの実装方法:  
# MAGIC   https://mlflow.org/docs/latest/traditional-ml/creating-custom-pyfunc/part2-pyfunc-components.html#the-power-of-custom-pyfunc-models
# MAGIC

# COMMAND ----------

import mlflow

class CustomModel(mlflow.pyfunc.PythonModel):
    def __init__(self, model: RandomForestClassifier, encoder: OneHotEncoder):
        self._model = model
        self._enc = encoder
    
    def load_context(self, context):
        with open(context.artifacts["bundled_file"], "rt") as f:
            self.bundled_file_data = f.read()
    
    def predict(self, context, model_input, params=None):
        y = self._model.predict(model_input)
        y = self._enc.inverse_transform(y)

        print(self.bundled_file_data)

        return y[:,0]

with mlflow.start_run():
    # Model packaging as CustomModel
    custom_model = CustomModel(model, ohe_trans)
    
    # Track CustomModel
    artifacts = { "bundled_file": "sample-custom/bundled" }
    signature = mlflow.models.infer_signature(x_train, y_train)
    model_info_3 = mlflow.pyfunc.log_model(
        python_model=custom_model,
        artifact_path="model",
        signature=signature,
        input_example=x_train[:10],
        artifacts=artifacts
    )
    mlflow.set_tag("type", "PackagedModel")


# COMMAND ----------

# MAGIC %md
# MAGIC ## エクスポート & インポート
# MAGIC ローカルへモデルを書き出したり、他所から取ってきたモデルを取り込むことも可能。

# COMMAND ----------

# トラッキング記録からモデルを取得
print(model_info_1.model_uri)
model_1 = mlflow.pyfunc.load_model(model_info_1.model_uri)

print(model_info_2.model_uri)
model_2 = mlflow.sklearn.load_model(model_info_2.model_uri)

# COMMAND ----------

# モデルを手元へエクスポート (アーティファクトから. 方法1)
# mlflow.artifacts.download_artifacts("dbfs:/databricks/mlflow-tracking/1478265101077117/646f425ef1014acd8b78303e241995a2/artifacts/model", dst_path="exported")

# モデルを手元へエクスポート (アーティファクトから. 方法2)
mlflow.artifacts.download_artifacts(model_info_1.model_uri, dst_path="exported")

# モデルを手元へエクスポート (インスタンスから)
mlflow.sklearn.save_model(
    model, "exported/saved_model", signature=signature, input_example=x_train[:10]
)

# モデルを手元からインポート
model_1 = mlflow.pyfunc.load_model("exported/model/")

# COMMAND ----------

# MAGIC %md
# MAGIC # Registry
# MAGIC モデルのライフサイクル管理向け機能を提供。モデルへ名前を付けて登録し、バージョン管理が出来る。モデルは既定では Unity Catalog へ保存される。
# MAGIC
# MAGIC * https://mlflow.org/docs/latest/model-registry.html

# COMMAND ----------

# MAGIC %md
# MAGIC ## レジストリへ登録

# COMMAND ----------

# mlflow.set_registry_uri("databricks-uc")

# モデル登録 (推論器 方法1)
mlflow.register_model("exported/model/", f"{WORKSPACE_CATALOG}.iris-estimator-imported")

# モデル登録 (推論器 方法2)
# mlflow.register_model('runs:/646f425ef1014acd8b78303e241995a2/model', f"{WORKSPACE_CATALOG}.iris-estimator")
model_ver_1 = mlflow.register_model(model_info_1.model_uri, "iris-estimator")

# モデル登録 (前処理)
# mlflow.register_model('runs:/646f425ef1014acd8b78303e241995a2/post', f"{WORKSPACE_CATALOG}.iris-target-encoder")
model_ver_2 = mlflow.register_model(model_info_2.model_uri, "iris-target-encoder")

# COMMAND ----------

# MAGIC %md
# MAGIC ## レジストリから取得

# COMMAND ----------

model_1 = mlflow.pyfunc.load_model(f"models:/{WORKSPACE_CATALOG}.iris-estimator/{model_ver_1.version}")
model_2 = mlflow.sklearn.load_model(f"models:/{WORKSPACE_CATALOG}.iris-target-encoder/{model_ver_2.version}")

# COMMAND ----------

from mlflow import MlflowClient
client = MlflowClient()

# モデルへエイリアス割り当て
client.set_registered_model_alias(f"{WORKSPACE_CATALOG}.iris-estimator", "confirmed", model_ver_1.version)
# エイリアスでモデル取得
client.get_model_version_by_alias(f"{WORKSPACE_CATALOG}.iris-estimator", "confirmed")
# モデルからエイリアス削除
# client.delete_registered_model_alias("{WORKSPACE_CATALOG}.iris-estimator", "confirmed")

# COMMAND ----------

from mlflow import MlflowClient
client = MlflowClient()

# 本番用へプロモート
client.copy_model_version(
    src_model_uri=f"models:/{WORKSPACE_CATALOG}.iris-estimator@confirmed",
    dst_name=f"{WORKSPACE_CATALOG}.iris-estimator-production",
)
client.set_registered_model_alias(f"{WORKSPACE_CATALOG}.iris-estimator-production", "confirmed", model_ver_1.version)

# COMMAND ----------

# MAGIC %md
# MAGIC # Serving
# MAGIC 推論機能を Apache Spark 上で UDF や REST API サーバーとして提供可能

# COMMAND ----------

# MAGIC %md
# MAGIC ## Spark UDF
# MAGIC * https://mlflow.org/docs/latest/models.html#export-a-python-function-model-as-an-apache-spark-udf

# COMMAND ----------


df_date = spark.createDataFrame(data, schema="f1 double, f2 double, f3 double, f4 double")
df_target = spark.createDataFrame(target[:, np.newaxis])

# COMMAND ----------

apply_model_udf = mlflow.pyfunc.spark_udf(spark, f"models:/{WORKSPACE_CATALOG}.iris-estimator-production@confirmed", result_type="array<float>")

# COMMAND ----------

import pyspark.sql.functions as F
import pyspark.sql.types as T
import pandas as pd

@F.pandas_udf(returnType="int")
def convert_pred(vals: pd.Series) -> pd.Series:
    return vals.map(lambda aa: np.argmax(aa))

(df_date
    .withColumn("prediction", apply_model_udf(F.struct("f1", "f2", "f3", "f4")))
    .withColumn("prediction_converted", convert_pred("prediction"))
    .display()
)

# COMMAND ----------

# MAGIC %md
# MAGIC ## API Server
# MAGIC REST API サーバーを作成可能。  
# MAGIC (プライベートサブネット内に設置しインターネットからアクセスさせない方法は不明)
# MAGIC
# MAGIC * エンドポイント作成: https://docs.databricks.com/ja/machine-learning/model-serving/create-manage-serving-endpoints.html
# MAGIC * 推論実行: https://docs.databricks.com/ja/machine-learning/model-serving/score-custom-model-endpoints.html

# COMMAND ----------

import os
import requests
import numpy as np
from urllib import request
import pandas as pd
import json

DATABRICKS_TOKEN = "..."
DATABRICKS_ENDPOINT_URL = "https://HOGEHOGE.cloud.databricks.com/serving-endpoints/iris-estimator/invocations"
def invoke_predict(input_df: pd.DataFrame):
    req = request.Request(
        DATABRICKS_ENDPOINT_URL,
        headers= {
            "Authorization": f"Bearer {DATABRICKS_TOKEN}",
            "Content-Type": "application/json"
        },
        data=json.dumps({ 'dataframe_split': input_df.to_dict(orient='split') }).encode("utf8"),
    )
    res = request.urlopen(req)
    return json.load(res)

invoke_predict(
    pd.DataFrame(
        [
            [5.6, 2.8, 4.9, 2],
            [5.8, 2.6, 4, 1.2],
            [4.4, 3.2, 1.3, 0.2],
            [7.2, 3.6, 6.1, 2.5],
            [5.1, 3.3, 1.7, 0.5],
            [6.7, 3.3, 5.7, 2.1],
            [5.5, 3.5, 1.3, 0.2],
            [6.3, 2.9, 5.6, 1.8],
            [5.7, 3.8, 1.7, 0.3],
            [5.5, 2.6, 4.4, 1.2]
        ],
        columns=["f1", "f2", "f3", "f4"]
    )
)

# COMMAND ----------

# MAGIC %sql
# MAGIC -- SQL からモデルを使用
# MAGIC -- 現在は一部のユーザのみ使用可能
# MAGIC -- https://docs.databricks.com/ja/sql/language-manual/functions/ai_query.html
# MAGIC
# MAGIC -- select
# MAGIC --   ai_query(
# MAGIC --     'iris-estimator',
# MAGIC --     named_struct("f1", f1, "f2", f2, "f3", f3, "f4", f4),
# MAGIC --     returnType => schema_of_json('@outputJson')
# MAGIC --   )
# MAGIC -- from (values (5.6, 2.8, 4.9, 2), (5.8, 2.6, 4, 1.2), (4.4, 3.2, 1.3, 0.2)) as (f1, f2, f3, f4)