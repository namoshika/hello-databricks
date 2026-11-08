"""Unity Catalog の Python 関数を登録し、動作を確認する。

登録する関数は src/hello_agentbricks/functions/ に置き、関数ごとにセル（# %%）を足す。
事前に、スキーマ workspace.hello_agent を作成しておく。
アプリのコードは、パッケージ hello_agentbricks として import できる（uv sync でインストールされる）。
実行はプロジェクトのルートで `uv run python scripts/register_functions.py`。
"""

# %% 準備
from unitycatalog.ai.core.databricks import DatabricksFunctionClient

from hello_agentbricks.functions.weather import get_weather

PROFILE = "DEFAULT"
CATALOG = "workspace"
SCHEMA = "hello_agent"

client = DatabricksFunctionClient(profile=PROFILE)

# %% get_weather：登録して（同名の関数があれば上書きする）、サーバーレスで動作を確認する
info = client.create_python_function(
    func=get_weather, catalog=CATALOG, schema=SCHEMA, replace=True
)
print(f"登録・更新した関数: {info.full_name}")

result = client.execute_function(
    function_name=f"{CATALOG}.{SCHEMA}.get_weather",
    parameters={"city": "東京"},
)
if result.error:
    raise RuntimeError(result.error)
print(f"実行結果: {result.value}")
