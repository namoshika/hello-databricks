import pyspark.sql.functions as F
from pyspark import pipelines as dp
from langchain_google_genai import GoogleGenerativeAIEmbeddings

import libs.chunkstore.databricks as chunkstore


@dp.table(
    name="g_monthly_news_embed",
    table_properties={"delta.enableChangeDataFeed": "true"},
    comment="月次ニュースの埋め込みベクトルテーブル",
)
def g_monthly_news_embed():
    src_catalog = spark.conf.get("src_catalog")
    src_schema = spark.conf.get("src_schema")

    # ソーステーブルをストリーミングテーブルとして読み込み
    news_df = spark.readStream.table(f"{src_catalog}.{src_schema}.b_monthly_news")

    # 埋め込み表現生成用の UDF を作成
    api_key = dbutils.secrets.get(scope="agent", key="GEMINI_API_KEY")
    embr = chunkstore.emb_udf_factory(lambda: GoogleGenerativeAIEmbeddings(model="gemini-embedding-001", api_key=api_key))

    # content 列に対して埋め込みベクトルを生成
    embed_df = news_df.withColumn("embedding", embr(F.col("content")))
    return embed_df
