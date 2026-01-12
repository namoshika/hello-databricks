from langchain_core.documents import Document
from langchain_text_splitters import MarkdownHeaderTextSplitter
from .. import absclass


class MarkdownDocumentStore(absclass.DocumentStore):
    def __init__(self, store_name: str, chunk_store: absclass.ChunkStore):
        self._store_name = store_name
        self._chunk_store = chunk_store
        self._store = None

    def connect(self) -> None:
        if self._store is not None:
            return
        self._store = self._chunk_store.get_vectorstore(self._store_name)

    def search_documents(self, query: str, top_k: int) -> list[Document]:
        return self._store.similarity_search(query, k=top_k)

    def import_documents(self, documents: list[Document]) -> None:
        # 読み込んだ Markdown を章毎に分割
        docs_chunked = []
        doc_splitter = MarkdownHeaderTextSplitter([("#", "section")])
        for doc_origin in documents:
            # テキストを細かいチャンクに分解
            doc_splitted = doc_splitter.split_text(doc_origin.page_content)
            for item in doc_splitted:
                item.metadata.update(doc_origin.metadata)
                docs_chunked.append(item)

        self._store.add_documents(docs_chunked)
