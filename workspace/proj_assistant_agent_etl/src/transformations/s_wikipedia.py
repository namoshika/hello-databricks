import pyspark.sql.functions as F
from pyspark import pipelines as dp


@dp.table(
    name="s_wikipedia",
    comment="Wikipedia Markdown ファイルに document_id を付与したテーブル",
    table_properties={
        "delta.enableChangeDataFeed": "true",
        "delta.enableDeletionVectors": "true",
        "delta.enableRowTracking": "true",
    },
)
def s_wikipedia():
    df = spark.readStream.table("b_wikipedia")  # noqa: F821
    df = df.where(F.col("content").isNotNull())
    df = df.withColumn(
        "extracted",
        F.ai_extract(
            F.col("content"),
            {
                "content": {
                    "type": "string",
                    "description": "Markdown content of the main body, formatted without HTML tags, ensuring all elements that can be expressed in Markdown syntax are accurately represented. This includes all sections, such as external links, and must capture the entire content of the input document comprehensively.",
                },
            },
            options={
                "version": "2.0",
                "instructions": "",
            },
        ),
    )
    df = df.select(
        F.col("document_id"),
        F.try_variant_get("metadata", "$.original_url", "string").alias("original_url"),
        F.try_variant_get("metadata", "$.title", "string").alias("title"),
        F.try_variant_get("extracted", "$.response.content", "string").alias("content"),
        F.try_variant_get("extracted", "$.error_message", "string").alias("err_msg"),
    )
    return df
