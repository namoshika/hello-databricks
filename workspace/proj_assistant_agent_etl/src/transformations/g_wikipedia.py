import pyspark.sql.functions as F
from pyspark import pipelines as dp

from utilities import document


@dp.table(
    name="g_wikipedia_c1024",
    comment="Wikipedia Markdown ファイルをチャンキングしたテーブル",
    table_properties={
        "delta.enableChangeDataFeed": "true",
        "delta.enableDeletionVectors": "true",
        "delta.enableRowTracking": "true",
    },
)
def g_wikipedia_c1024():
    df = spark.readStream.table("s_wikipedia")  # noqa: F821
    df = df.withColumn(
        "chunks", document.split_text(F.col("content"), F.lit(1024), F.lit(200))
    )
    df = df.select(
        F.col("*"),
        F.posexplode("chunks").alias("chunk_id", "chunk_text"),
    )
    df = df.select(
        F.col("document_id"),
        F.col("chunk_id"),
        F.col("original_url"),
        F.col("chunk_text").alias("content"),
    )
    return df


@dp.table(
    name="g_wikipedia_c800",
    comment="Wikipedia Markdown ファイルをチャンキングしたテーブル",
    table_properties={
        "delta.enableChangeDataFeed": "true",
        "delta.enableDeletionVectors": "true",
        "delta.enableRowTracking": "true",
    },
)
def g_wikipedia_c800():
    df = spark.readStream.table("s_wikipedia")  # noqa: F821
    df = df.withColumn(
        "chunks", document.split_text(F.col("content"), F.lit(800), F.lit(80))
    )
    df = df.select(
        F.col("*"),
        F.posexplode("chunks").alias("chunk_id", "chunk_text"),
    )
    df = df.select(
        F.col("document_id"),
        F.col("chunk_id"),
        F.col("original_url"),
        F.col("chunk_text").alias("content"),
    )
    return df
