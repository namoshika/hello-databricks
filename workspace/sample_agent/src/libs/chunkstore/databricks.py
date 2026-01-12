import pandas as pd
from typing import Callable
from pyspark.sql.functions import pandas_udf
from pyspark.sql.types import ArrayType, FloatType
from databricks_langchain import DatabricksVectorSearch
from langchain_core.embeddings import Embeddings
from langchain_core.vectorstores import VectorStore
from .. import absclass


class DatabricksChunkStore(absclass.ChunkStore):
    def __init__(
        self,
        embedding: Embeddings,
        dimention_size: int,
        text_col: str,
        endpoint_name: str,
    ):
        self.text_col = text_col
        self.embedding = embedding
        self.dimention_size = dimention_size
        self.endpoint_name = endpoint_name

    def get_vectorstore(self, store_name: str) -> VectorStore:
        return DatabricksVectorSearch(
            store_name, self.endpoint_name, self.embedding, self.text_col
        )

def emb_udf_factory(factory: Callable[[], Embeddings]):
    """
    Spark DataFrame の文字列列から埋め込み表現列を生成
    """

    @pandas_udf(ArrayType(FloatType()))
    def emb_udf(text_col: pd.Series) -> pd.Series:
        # return pd.Series([[float(text_col.size)] for _ in text_col])
        embedding = factory()
        doc_embed = pd.Series(
            [embbed for embbed in embedding.embed_documents(text_col.tolist())]
        )
        return doc_embed

    return emb_udf
