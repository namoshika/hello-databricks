import pyspark.sql.functions as F
from pyspark import pipelines as dp

from utilities import document, utils


@dp.table(
    name="b_wikipedia",
    comment="Wikipedia Markdown ファイルの取り込みテーブル",
    table_properties={
        "delta.enableChangeDataFeed": "true",
        "delta.enableDeletionVectors": "true",
        "delta.enableRowTracking": "true",
    },
)
def b_wikipedia():
    DATA_BUCKET_NAME = spark.conf.get("DATA_BUCKET_NAME")  # noqa: F821
    df = (
        spark.readStream.format("cloudFiles")  # noqa: F821
        .option("cloudFiles.format", "text")
        .option("wholeText", "true")
        .option("recursiveFileLookup", "true")
        .option("pathGlobFilter", "*.md")
        .load(f"s3://{DATA_BUCKET_NAME}/data/wikipedia_ja/")
        .select(
            F.col("_metadata.file_path").alias("file_path"),
            F.col("value").alias("file_content"),
        )
    )
    df = document.parse_markdown(df, md_colname="file_content")
    df = df.select(
        utils.uuid5(F.col("file_path")).alias("document_id"),
        F.col("file_path"),
        F.col("metadata"),
        F.col("content"),
    )
    return df
