import datetime
import json
from collections.abc import Iterator

import pandas as pd
import yaml
from langchain_text_splitters import RecursiveCharacterTextSplitter
from pyspark.sql import DataFrame
from pyspark.sql.functions import col, pandas_udf, parse_json
from pyspark.sql.types import ArrayType, StringType, StructField, StructType


@pandas_udf(ArrayType(StringType()))
def split_text(
    texts: pd.Series, chunk_size: pd.Series, chunk_overlap: pd.Series
) -> pd.Series:
    """content 列をチャンク化した列を返す pandas UDF.

    Args:
        texts: チャンク化対象の文字列を持つ列 (例: F.col("content"))。
        chunk_size: チャンクの最大文字数 (例: F.lit(1024))。
        chunk_overlap: 隣接チャンク間で重複させる文字数 (例: F.lit(200))。

    Returns:
        チャンク文字列のリストを持つ配列型の列。
    """
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size.iloc[0],
        chunk_overlap=chunk_overlap.iloc[0],
    )
    return texts.map(lambda text: splitter.split_text(text) if text is not None else [])


def parse_markdown(df: DataFrame, md_colname: str) -> DataFrame:
    """markdown 本文列を持つ DataFrame にフロントマター解析結果の列を追加する.

    Args:
        df: markdown 本文列を持つ DataFrame。
        md_colname: markdown 本文文字列を持つ列名。

    Returns:
        content (本文) と metadata (Variant 型のフロントマター) 列を追加した DataFrame。
    """

    def _parse_partition(iterator: Iterator[pd.DataFrame]) -> Iterator[pd.DataFrame]:
        for pdf in iterator:
            bodies, metadatas = zip(*pdf[md_colname].map(_parse_markdown_text))
            pdf["content"] = bodies
            pdf["metadata"] = [json.dumps(m, ensure_ascii=False) for m in metadatas]
            yield pdf

    output_schema = StructType(
        list(df.schema)
        + [
            StructField("content", StringType(), True),
            StructField("metadata", StringType(), True),
        ]
    )

    output_df = df
    output_df = output_df.mapInPandas(_parse_partition, schema=output_schema)
    output_df = output_df.withColumn("metadata", parse_json(col("metadata")))
    return output_df


def _parse_markdown_text(content: str) -> tuple[str, dict]:
    """Markdown テキストからフロントマターを metadata として取り出す.

    Args:
        content: フロントマターを含む可能性がある Markdown テキスト。

    Returns:
        (本文, フロントマターの metadata 辞書) のタプル。
    """
    raw_front_matter, body = _split_front_matter(content)
    fm: dict = (
        yaml.safe_load(raw_front_matter) or {} if raw_front_matter is not None else {}
    )
    metadata = {
        k: v.isoformat() if isinstance(v, (datetime.date, datetime.datetime)) else v
        for k, v in fm.items()
    }
    return body, metadata


def _split_front_matter(text: str) -> tuple[str | None, str]:
    """先頭・終端を `---` で囲むフロントマター記法で text を分割する.

    改行コードは CRLF/LF のどちらも受け付ける。

    Args:
        text: フロントマターを含む可能性があるテキスト。

    Returns:
        区切りが見つかった場合は (フロントマターの YAML 文字列, 本文) のタプル。
        見つからない場合は (None, text) を返し、フロントマター無しか否かの
        判定を呼び出し元に委ねる。
    """
    FRONT_MATTER_DELIMITER = "---\n"
    normalized = text.replace("\r\n", "\n")
    head, delimiter, rest = normalized.partition(FRONT_MATTER_DELIMITER)

    # フロントマターの始端無し、または先頭に余計な文字列がある場合はフロントマター無しとみなす
    if head != "" or not delimiter:
        return None, text
    # フロントマターの終端が見つからない場合もフロントマター無しとみなす
    raw_front_matter, delimiter, body = rest.partition(f"\n{FRONT_MATTER_DELIMITER}")
    if not delimiter:
        return None, text

    # フロントマターの終端が見つかった場合は (フロントマター, 本文) を返す
    return raw_front_matter, body
