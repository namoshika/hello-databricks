# Wiki.js on Databricks App
このドキュメントは、人間が実施する必要がある作業をステップごとにまとめたものです。

## 前提条件

- Databricks CLI がインストール済み
- Databricks ワークスペースへの認証が設定済み
- プロジェクトディレクトリ (`proj_dashboard`) で作業する

## ステップ 1: Secret の作成

```bash
# スコープ作成
databricks secrets create-scope dashboard_wiki

# シークレット作成
databricks secrets put-secret dashboard_wiki wikiuser_password --string-value "<GENERATED_PASSWORD>"
databricks secrets list-secrets dashboard_wiki
```

## ステップ 2: バンドルのデプロイ（Lakebase + App）

```bash
# バンドル設定を検証
databricks bundle validate --target dev

# デプロイ（Lakebase プロジェクト・ブランチ・App をまとめて作成）
databricks bundle deploy --target dev
```

## ステップ 3: wikiuser の作成（初回のみ）

Lakebase プロジェクトが作成された後、native Postgres ユーザーを作成します。

```bash
# wikiuser を作成し、public スキーマへの権限を付与
databricks psql --project dashboard-wikidb --branch production -- \
  -d databricks_postgres \
  -c "CREATE USER wikiuser WITH PASSWORD '<GENERATED_PASSWORD>';" \
  -c "GRANT ALL ON SCHEMA public TO wikiuser;"
```

## ステップ 4: App の起動

```bash
# App を起動（bundle deploy だけでは起動しない）
databricks bundle run wiki_app --target dev

# ステータス確認
databricks apps get "dashboard-wiki-dev"

# ログ確認（トラブルシューティング用）
databricks apps logs "dashboard-wiki-dev"
```

## ステップ 6: 動作確認

1. Databricks ワークスペースの Apps ページを開く
2. `dashboard-wiki-dev` を選択
3. Wiki.js 初期セットアップ画面が表示されることを確認
4. 管理者アカウントを作成
5. Wiki ページを作成・編集して動作確認
