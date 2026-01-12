import os
import mlflow
import mlflow.models

from databricks.sdk import WorkspaceClient
from langchain.agents import create_agent
from langchain_core.documents import Document
from langchain_google_genai.chat_models import ChatGoogleGenerativeAI
from langchain.tools import tool

from libs.utils import LangGraphWrapper
from libs.documentstore.markdown import MarkdownDocumentStore
from libs.retriever import DbxDocSampleChunkStore

AGENT_NAME = "agent"
GEMINI_MODEL_ID = "gemini-3-flash-preview"
VECTOR_SEARCH_ENDPOINT = "vsi_endpoint"
VECTOR_SEARCH_INDEX = "workspace.default.monthly_news_vsi"

# LLM の APIキーを環境変数から取得。無い場合はシークレットから取得。認証情報は
# シークレットを通して渡したいが、モデルサービングからシークレットの参照が不可。
# モデルサービングはデプロイ時の環境変数がソースにシークレットを指定可能。これを使う。
# 参考: https://docs.databricks.com/aws/en/machine-learning/model-serving/store-env-variable-model-serving
api_key = os.environ.get("GEMINI_API_KEY")
if api_key is None:
    w = WorkspaceClient()
    api_key = w.dbutils.secrets.get(scope="agent", key="GEMINI_API_KEY")

llm = ChatGoogleGenerativeAI(model=GEMINI_MODEL_ID, api_key=api_key)
doc_cs = DbxDocSampleChunkStore(VECTOR_SEARCH_ENDPOINT, api_key)
doc_ds = MarkdownDocumentStore(VECTOR_SEARCH_INDEX, doc_cs)


@tool
def get_weather(city: str) -> str:
    """Get weather for a given city."""
    return f"It's always sunny in {city}!"


@tool(response_format="content_and_artifact")
def search_news_history(search_query: str) -> list[Document]:
    """Search news history for a given query."""
    doc_ds.connect()
    tmpl = " title: {doc_name}  \n" + "===  \n" + "{doc_content}  \n\n"

    results = doc_ds.search_documents(search_query, top_k=5)
    contents = [
        tmpl.format(
            doc_name=item.metadata["file_name"],
            doc_content=item.page_content,
        )
        for item in results
    ]
    contents = "".join(contents)
    return contents, results


agent = create_agent(
    model=llm,
    tools=[get_weather, search_news_history],
    system_prompt="You are a helpful assistant",
)

agent_wrapped = LangGraphWrapper(agent)
mlflow.models.set_model(agent_wrapped)
