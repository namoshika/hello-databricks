CREATE STREAMING TABLE tenki_bronze AS
SELECT * FROM STREAM read_files(
  's3://${DATA_BUCKET_NAME}/data/tenki/',
  format => 'csv',
  header => 'true',
  inferSchema => 'true',
  mergeSchema => 'true'
);