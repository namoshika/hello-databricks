from langchain_core.embeddings import Embeddings
from langchain_core.vectorstores import VectorStore
from langchain_postgres import PGEngine, PGVectorStore, Column
from .. import absclass


class PGVectorChunkStore(absclass.ChunkStore):
    def __init__(
        self,
        engine: PGEngine,
        metadata_columns: list[Column],
        embedding: Embeddings,
        dimention_size: int,
    ):
        self.engine = engine
        self.metadata_columns = metadata_columns
        self.embedding = embedding
        self.dimention_size = dimention_size

    def get_vectorstore(self, table_name: str) -> VectorStore:
        try:
            vectorstore = PGVectorStore.create_sync(
                engine=self.engine,
                table_name=table_name,
                embedding_service=self.embedding,
                metadata_columns=[item.name for item in self.metadata_columns],
            )
        except ValueError as e:
            self._init_table(table_name)
            vectorstore = PGVectorStore.create_sync(
                engine=self.engine,
                table_name=table_name,
                embedding_service=self.embedding,
                metadata_columns=[item.name for item in self.metadata_columns],
            )
        return vectorstore

    def _init_table(self, table_name: str):
        self.engine.init_vectorstore_table(
            table_name,
            self.dimention_size,
            metadata_columns=self.metadata_columns,
        )
