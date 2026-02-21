import pyspark.pipelines as dp
import pyspark.sql.functions as F


@dp.table(
    name="b_monthly_news",
    table_properties={"delta.enableChangeDataFeed": "true"},
    comment="月次ニュースデータ",
)
def b_monthly_news():
    return (
        spark.readStream.format("cloudFiles")
        .option("cloudFiles.format", "text")
        .option("wholetext", "true")
        .load(f"s3://{spark.conf.get('DATA_BUCKET_NAME')}/data/monthly_news/")
        .select("_metadata.file_name", F.col("value").alias("content"))
    )
