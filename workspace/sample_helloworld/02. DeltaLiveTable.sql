-- Databricks notebook source

CREATE STREAMING LIVE TABLE tenki_bronze AS
SELECT * FROM STREAM read_files(
  's3://${DATA_BUCKET_NAME}/data/tenki/',
  format => 'csv',
  header => 'true',
  inferSchema => 'true',
  mergeSchema => 'true'
)

-- COMMAND ----------

CREATE LIVE TABLE tenki_silver (
  CONSTRAINT cons_ymd_is_notnull EXPECT (ymd IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT cons_area1_is_notnull EXPECT (area_1 IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT cons_area2_is_notnull EXPECT (area_2 IS NOT NULL) ON VIOLATION DROP ROW
)
AS
SELECT * FROM LIVE.tenki_bronze

-- COMMAND ----------

CREATE LIVE TABLE tenki_gold AS
SELECT
  date_format(ymd, 'yyyy-MM') AS ym,
  area_2 AS area,
  AVG(`平均気温（℃）計測値`) AS temp
FROM LIVE.tenki_silver
GROUP BY date_format(ymd, 'yyyy-MM'), area_2