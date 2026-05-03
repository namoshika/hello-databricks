import json
from pathlib import Path

import pytest
from config_loader import ConfigLoader


_DATA_DIR = Path(__file__) / "../../data/config_loader"


class TestLoadRootConfig:
    def test_load_config(self):
        """設定ファイルを読み込めること"""
        loader = ConfigLoader()
        loader.root_path = _DATA_DIR / "root"

        config = loader.load_root("config_dev.json")

        assert config["environment"] == "dev"
        assert config["catalog"] == "main"
        assert config["schema"] == "default"

    def test_load_subdirectory(self):
        """サブディレクトリ内ファイルを読み込めること"""
        loader = ConfigLoader()
        loader.root_path = _DATA_DIR / "root"

        config = loader.load_root("interface/IF001.json")

        assert config["interface_id"] == "IF001"
        assert config["endpoint"] == "https://api.example.com"

    def test_load_empty_json(self):
        """空 JSON を空辞書として読み込めること"""
        loader = ConfigLoader()
        loader.root_path = _DATA_DIR / "root"

        config = loader.load_root("empty.json")

        assert config == {}

    def test_invalid_json_raises(self):
        """不正な JSON で例外をスローすること"""
        loader = ConfigLoader()
        loader.root_path = _DATA_DIR / "invalid"

        with pytest.raises(json.JSONDecodeError):
            loader.load_root("invalid_syntax.json")


class TestLoadProjConfig:
    def test_load_config(self):
        """設定ファイルを読み込めること"""
        loader = ConfigLoader()
        loader.proj_path = _DATA_DIR / "sub_project"

        config = loader.load_proj("config_dev.json")

        assert config["job_name"] == "test_job_dev"
        assert config["parallelism"] == 2

    def test_load_subdirectory(self):
        """サブディレクトリ内ファイルを読み込めること"""
        loader = ConfigLoader()
        loader.proj_path = _DATA_DIR / "sub_project"

        config = loader.load_proj("interface/IF001.json")

        assert config["interface_id"] == "IF001"
        assert config["endpoint"] == "https://api.example.com"

    def test_load_empty_json(self):
        """空 JSON を空辞書として読み込めること"""
        loader = ConfigLoader()
        loader.proj_path = _DATA_DIR / "sub_project"

        config = loader.load_proj("empty.json")

        assert config == {}

    def test_invalid_json_raises(self):
        """不正な JSON で例外をスローすること"""
        loader = ConfigLoader()
        loader.proj_path = _DATA_DIR / "sub_project"

        with pytest.raises(json.JSONDecodeError):
            loader.load_proj("invalid_syntax.json")
