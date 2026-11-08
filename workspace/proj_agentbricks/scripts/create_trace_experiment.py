"""トレースを Unity Catalog のテーブルに保存する MLflow 実験を作る（既にあれば再利用する）。

事前に、スキーマ workspace.agentbricks_traces を作成しておく。
実験は、自分のホームフォルダ /Users/<自分のメールアドレス>/hello-agentbricks に作る。
実行はプロジェクトのルートで
`DATABRICKS_CONFIG_PROFILE=DEFAULT uv run python scripts/create_trace_experiment.py <SQL ウェアハウスの ID>`。
"""

import os
import sys

import mlflow
from databricks.sdk import WorkspaceClient
from mlflow.entities.trace_location import UnityCatalog

user = WorkspaceClient().current_user.me().user_name
EXPERIMENT_NAME = f"/Users/{user}/hello-agentbricks"

os.environ["MLFLOW_TRACING_SQL_WAREHOUSE_ID"] = sys.argv[1]
mlflow.set_tracking_uri("databricks")

experiment = mlflow.set_experiment(
    experiment_name=EXPERIMENT_NAME,
    trace_location=UnityCatalog(
        catalog_name="workspace",
        schema_name="agentbricks_traces",
        table_prefix="hello_agentbricks",
    ),
)
print(f"実験: {EXPERIMENT_NAME}（ID {experiment.experiment_id}）")
print(f"保存先: {experiment.trace_location.full_otel_spans_table_name}")
