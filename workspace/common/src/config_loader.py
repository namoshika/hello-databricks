import json
from pathlib import Path


class ConfigLoader:
    """設定ファイルの読み込みを提供するクラス"""

    def __init__(self, proj_path: str = ".."):
        """
        Args:
            proj_path:
                ノートブックから見たサブプロジェクトルートへの相対パス
                デフォルト: ".." (notebooks/ ディレクトリから一つ上)
        """
        # config_loader.py の位置から root_path を自動計算
        # common/src/config_loader.py から ../../ でプロジェクトルート
        self.root_path = (Path(__file__) / "../../..").resolve()

        # proj_path をノートブックからの相対パスとして解決
        # Path(".").resolve() は Databricks ノートブック実行時、
        # ノートブックが配置されているディレクトリを返す
        current_dir = Path(".").resolve()
        self.proj_path = (current_dir / proj_path).resolve()

    def load_root(self, name: str) -> dict:
        """ルート設定ファイルを読み込む"""
        config_path = self.root_path / "config" / name
        config_path = config_path.resolve()
        return json.loads(config_path.read_text(encoding="utf-8"))

    def load_proj(self, name: str) -> dict:
        """サブプロジェクト設定ファイルを読み込む"""
        config_path = self.proj_path / "config" / name
        config_path = config_path.resolve()
        return json.loads(config_path.read_text(encoding="utf-8"))
