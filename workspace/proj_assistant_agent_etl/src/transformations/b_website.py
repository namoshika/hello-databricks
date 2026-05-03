import datetime
import re
import uuid
from collections.abc import Iterator

import pandas as pd
import yaml
from pyspark import pipelines as dp
from pyspark.sql.functions import col
from pyspark.sql.types import StringType, StructField, StructType


@dp.table(
    name="b_website",
    comment="ウェブサイト Markdown ファイルの取り込みテーブル",
    table_properties={"delta.enableChangeDataFeed": "true"},
)
def b_website():
    DATA_BUCKET_NAME = spark.conf.get("DATA_BUCKET_NAME")  # noqa: F821
    df = (
        spark.readStream.format("cloudFiles")  # noqa: F821
        .option("cloudFiles.format", "text")
        .option("wholeText", "true")
        .option("recursiveFileLookup", "true")
        .option("pathGlobFilter", "*.md")
        .load(f"s3://{DATA_BUCKET_NAME}/data/website/")
        .select(
            col("_metadata.file_path").alias("file_path"),
            col("value").alias("file_content"),
        )
    )
    return df.mapInPandas(
        lambda it: parse_md_partition(it, "file_path", "file_content"),
        schema=StructType(
            [
                StructField("document_id", StringType(), False),
                StructField("original_url", StringType(), True),
                # VectorSearchIndex は MapType を格納できないため除外
                # terraform provider のバグで columns_to_sync が使えないため列自体を削除
                # 参考: https://github.com/databricks/terraform-provider-databricks/issues/5281
                # StructField("metadata", MapType(StringType(), StringType()), True),
                StructField("content", StringType(), True),
            ]
        ),
    )


# --------------------------------------------------------------
#  markdown パース
# (mapInPandas で各ワーカーへ転送されないため、テーブル定義と同居)
# --------------------------------------------------------------
FRONT_MATTER_RE = re.compile(r"^---\r?\n(.*?)\r?\n---\r?\n", re.DOTALL)


def parse_md_file(file_path: str, file_content: str) -> dict:
    m = FRONT_MATTER_RE.match(file_content)
    meta: dict[str, str] = {}
    body = file_content
    if m:
        fm: dict = yaml.safe_load(m.group(1)) or {}
        for k, v in fm.items():
            meta[str(k)] = (
                v.isoformat()
                if isinstance(v, (datetime.date, datetime.datetime))
                else str(v)
            )
        body = file_content[m.end() :]
    meta["file_path"] = file_path
    return {
        "document_id": str(uuid.uuid5(uuid.NAMESPACE_URL, file_path)),
        "original_url": meta.get("original_url"),
        # "metadata": meta,
        "content": body,
    }


def parse_md_partition(
    iterator: Iterator[pd.DataFrame],
    file_path_col: str,
    file_content_col: str,
) -> Iterator[pd.DataFrame]:
    for pdf in iterator:
        records = [
            parse_md_file(row[file_path_col], row[file_content_col])
            for _, row in pdf.iterrows()
        ]
        yield pd.DataFrame(records)
