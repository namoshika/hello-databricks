"""Unity Catalog に登録して実行できる、固定の応答を返す天気取得関数。"""


def get_weather(city: str) -> str:
    """指定した都市の現在の天気を返す。

    Args:
        city: 天気を知りたい都市の名前。

    Returns:
        都市名を含む、天気の文字列。
    """
    return f"{city}の天気は晴れ、気温は20℃です。"
