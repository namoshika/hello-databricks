from databricks_agentkit import DurableAgentServer, InvocationContext
from databricks_agentkit.langgraph import configure_tracing

from hello_agentbricks.agent import build_agent

configure_tracing()

app = DurableAgentServer()


@app.invoke
async def invoke(input, context: InvocationContext) -> dict:
    agent = await build_agent()
    result = await agent.ainvoke({"messages": input["messages"]})
    messages = result["messages"]
    return {
        "answer": messages[-1].content,
        "tool_calls": [c["name"] for m in messages for c in getattr(m, "tool_calls", [])],
    }
