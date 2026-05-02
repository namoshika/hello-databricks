# Databricks notebook source
# MAGIC %md
# MAGIC # 始めのデータ参照
# MAGIC サンプルデータを参照する

# COMMAND ----------

spark.read \
    .options(header=True, inferSchema=True) \
    .csv("/databricks-datasets/retail-org/customers/") \
    .display()

# COMMAND ----------

# MAGIC %md
# MAGIC # S3 を参照する
# MAGIC 参照する S3 バケットを Unity Volume として登録すると Databricks から参照可能。  
# MAGIC ※注: {DATA_BUCKET_NAME} はサンプルデータの格納用に用意したバケットに書き換える

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT *
# MAGIC FROM read_files(
# MAGIC   's3://{DATA_BUCKET_NAME}/data/tenki/',
# MAGIC   format => 'csv', header => 'true', inferSchema => 'true'
# MAGIC )

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT date_format(ymd, 'yyyy-MM') AS ym, area_2, AVG(`平均気温（℃）計測値`)
# MAGIC FROM read_files(
# MAGIC   's3://{DATA_BUCKET_NAME}/data/tenki/',
# MAGIC   format => 'csv', header => 'true', inferSchema => 'true'
# MAGIC )
# MAGIC GROUP BY date_format(ymd, 'yyyy-MM'), area_2
# MAGIC ORDER BY date_format(ymd, 'yyyy-MM'), AVG(`平均気温（℃）計測値`)
