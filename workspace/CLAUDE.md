# CLAUDE.md

このファイルは、リポジトリ内のコードを操作するエージェントへのガイダンスを提供します。

## ディレクトリの共通構造

各サブプロジェクトは以下の共通構造を持ち、必要に応じて各フォルダを持ちます。

```
<project>/
├── src/                  # Python ソースコード
├── resources/            # DML, ジョブ・パイプライン定義 YAML 類
├── tests/                # ユニットテスト
├── terraform/            # インフラ定義
├── databricks.yml        # Databricks アセットバンドル定義
├── pyproject.toml        # Python プロジェクト設定・依存関係
└── uv.lock               # uv ロックファイル
```

## 環境構築方法

依存管理には **`uv`** を使用します。各サブプロジェクトディレクトリで実行します。
Databricks 環境上で実行する場合は uv sync, run 時に `--active` を付与すること。

```bash
# 依存パッケージのインストール (dev 含む)
uv sync (--active)

# テスト実行
uv run  (--active) pytest

# カバレッジ付きで実行
uv run  (--active) pytest --cov=src
```

Databricks への接続認証は事前に設定します。

```bash
databricks configure
```

## デプロイ方法

`databricks.yml` を持つプロジェクトは Databricks Asset Bundles でデプロイします。

```bash
# バンドル設定の検証
databricks bundle validate

# dev へデプロイ
databricks bundle deploy --target dev

# prod へデプロイ
databricks bundle deploy --target prod
```

### ターゲットの違い

| 項目 | dev | prod |
|---|---|---|
| スキーマ | `usr_<ユーザー名>` (ユーザー個別) | `default` |
| ワークスペースパス | ユーザー個人領域 | `/Workspace/Shared/.bundle/<bundle名>` |
| ジョブスケジュール | 一時停止 | 有効 |
| リソース名 | `[dev <ユーザー名>]` プレフィックス付き | そのまま |

### バンドル変数

`catalog`、`schema`、`aws_s3_bucketname_storage` 等の設定値はバンドル変数として管理されており、ターゲットごとに上書きされます。必要に応じて `--var` オプションで指定できます。

```bash
databricks bundle deploy --target prod --var="catalog=my_catalog"
```