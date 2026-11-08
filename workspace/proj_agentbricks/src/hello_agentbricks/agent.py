from databricks_agentkit.langgraph import mcp_tools
from databricks_langchain import ChatDatabricks
from langchain.agents import create_agent

model = ChatDatabricks(endpoint="system.ai.gpt-oss-20b", use_ai_gateway=True)


async def build_agent():
    # agent.toml の [[tools]] を読み、MCP 経由でツールを取得する。
    tools = await mcp_tools()
    return create_agent(
        model=model,
        tools=tools,
        system_prompt="あなたは親切なアシスタントです。短く答えてください。",
    )
