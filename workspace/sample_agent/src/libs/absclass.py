import abc
from langchain_core.vectorstores import VectorStore
from langchain_core.documents import Document


class ChunkStore(abc.ABC):
    """VectorStore 生成を行うインターフェース。

    派生クラスを対象データセット & ドキュメント埋め込み戦略毎に作成する想定。
    クラスを分け、弄った際にすぐに元の戦略に戻せる状態にすることを推奨。
    """

    @abc.abstractmethod
    def get_vectorstore(self, store_name: str) -> VectorStore:
        raise NotImplementedError


class DocumentStore(abc.ABC):
    """Document 検索とインポートを行うインターフェース。

    派生クラスを対象データセット & チャンキング戦略毎に作成する想定。
    クラスを分け、弄った際にすぐに元の戦略に戻せる状態にすることを推奨。
    """

    @abc.abstractmethod
    def connect(self):
        raise NotImplementedError

    @abc.abstractmethod
    def search_documents(self, query: str, top_k: int) -> list[Document]:
        raise NotImplementedError

    @abc.abstractmethod
    def import_documents(self, documents: list[Document]) -> None:
        raise NotImplementedError
