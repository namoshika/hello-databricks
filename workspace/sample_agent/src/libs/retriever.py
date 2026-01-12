from langchain_google_genai import GoogleGenerativeAIEmbeddings
# from langchain_postgres import PGEngine, Column
# from .chunkstore.postgres import PGVectorChunkStore
from .chunkstore.databricks import DatabricksChunkStore


# class DocSampleChunkStore(PGVectorChunkStore):
#     def __init__(self, engine: PGEngine):
#         super().__init__(
#             engine,
#             [
#                 Column("path", "text", False),
#                 Column("source", "text", False),
#                 Column("section", "text", True),
#                 Column("date", "timestamp", True),
#                 Column("tags", "text", True),
#             ],
#             GoogleGenerativeAIEmbeddings(model="gemini-embedding-001"),
#             3072,
#         )

class DbxDocSampleChunkStore(DatabricksChunkStore):
    def __init__(self, endpoint_name: str, api_key: str):
        embr = GoogleGenerativeAIEmbeddings(model="gemini-embedding-001", api_key=api_key)
        super().__init__(embr, 3072, "content", endpoint_name)