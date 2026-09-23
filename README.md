# Hello Databricks World
Databricks 学習用の砂場

# Deployment
## 1. Prerequisites
以下がインストール済みであること。

* AWS
  * 入力データ用S3バケット (何でも良し。サンプルデータセットの置き場所として使用)
* Tools (Local)
  * terraform  
  * aws cli (認証情報も設定済みであること)
  * databricks cli

## 2. Build Infrastructure
初回のみ行う作業としてインフラの設定を行う。

**パラメーターファイルを編集**

```ini
# Rename: terraform/01-aws-global/terraform.tfvars.sample
# -> terraform.tfvars
aws_profile = "{AWS CLI のプロファイル名}"
aws_s3_bucketname_input = "{外部ストレージ用 S3 BucketName}"
# アカウントが複数有る場合はカンマ区切りで指定可能
# (AWS サブスクと Free Edition 両方を使う等)
dbx_account_id = "{DatabricksのアカウントID}"

# Rename: terraform/01-aws-regional/terraform.tfvars.sample
# -> terraform.tfvars
aws_profile = "{AWS CLI のプロファイル名}"
aws_region = "{デプロイ先 AWS リージョン}"
aws_s3_bucketname_workspace = "{ワークスペースカタログ用 S3 BucketName}"
dbx_account_id = "{DatabricksのアカウントID}"

# Rename: terraform/02-databricks-global/terraform.tfvars.sample
# -> terraform.tfvars
dbx_account_id = "{DatabricksのアカウントID}"
dbx_profile = "{Databricks CLI のプロファイル名}"

# Rename: terraform/02-databricks-regional/terraform.tfvars.sample
# -> terraform.tfvars
aws_region = "{デプロイ先 AWS リージョン}"
dbx_account_id = "{DatabricksのアカウントID}"
dbx_profile = "{Databricks CLI のプロファイル名}"

# Rename: terraform/03-databricks-workspace-classic/terraform.tfvars.sample
# -> terraform.tfvars
aws_region = "{デプロイ先 AWS リージョン}"
dbx_usermail_admin = "{管理者アカウントのメールアドレス}"
dbx_workspace_name = "{ワークスペースの名前}"

# Rename: terraform/03-databricks-workspace/terraform.tfvars.sample
# -> terraform.tfvars
aws_region = "{デプロイ先 AWS リージョン}"
dbx_usermail_admin = "{管理者アカウントのメールアドレス}"
dbx_workspace_name = "{ワークスペースの名前}"
```

**ターミナルを起動し実行**  
カレントディレクトリ: このリポジトリのルートディレクトリ

```sh
# サンプルデータセットを入力データ用S3バケットへアップ
aws s3 cp --recursive 'data/' 's3://{INPUT_STORAGE_BUCKET}/data/'

# Databricks CLI へ認証情報をセット
databricks auth login --account-id "{DatabricksのアカウントID}" --host "https://accounts.cloud.databricks.com" -p DEFAULT
databricks auth profiles

# ----------------------------
# 必須: 共通設定
# ----------------------------
# AWS の IAM 等グローバル設定を行う（リージョン非依存）。IAMロールの自己仮定の都合で2回デプロイする
terraform -chdir='terraform/01-aws-global' init
terraform -chdir='terraform/01-aws-global' apply -var 'is_firststep=true'
terraform -chdir='terraform/01-aws-global' apply

# AWS の S3 バケットとその専用 IAM ロールを設定する（リージョン依存）。01-aws-global とは独立して適用可能。IAMロールの自己仮定の都合で2回デプロイする
terraform -chdir='terraform/01-aws-regional' init
terraform -chdir='terraform/01-aws-regional' apply -var 'is_firststep=true'
terraform -chdir='terraform/01-aws-regional' apply

# Databricks のアカウントコンソールを設定（アカウント単位、リージョン非依存）
terraform -chdir='terraform/02-databricks-global' init
terraform -chdir='terraform/02-databricks-global' apply

# Databricks のメタストア・ストレージ設定を行う（リージョン依存）。02-databricks-global とは独立して適用可能
terraform -chdir='terraform/02-databricks-regional' init
terraform -chdir='terraform/02-databricks-regional' apply

# ----------------------------
# 任意: 顧客管理 VPC を使う場合
# ----------------------------
# AWS の設定を行う
terraform -chdir='terraform/01-aws-regional-cmvpc' init
terraform -chdir='terraform/01-aws-regional-cmvpc' apply

# Databricks のアカウントコンソールを設定
terraform -chdir='terraform/02-databricks-regional-cmvpc' init
terraform -chdir='terraform/02-databricks-regional-cmvpc' apply
```

## 3. Setup Workspace
ワークスペースを作成する際に都度実行する。  
作成すると AWS 上に NAT ゲートウェイが生成され、常に AWS の使用料金が発生する。そのため、使わない時は削除しておくと良い。

```sh
# Databricks のワークスペースを作成
# a. Databricks 管理 VPC を使う場合
terraform -chdir='terraform/03-databricks-workspace-classic' init
terraform -chdir='terraform/03-databricks-workspace-classic' apply

# b. 顧客管理 VPC を使う場合
terraform -chdir='terraform/03-databricks-workspace-cmvpc' init
terraform -chdir='terraform/03-databricks-workspace-cmvpc' apply

# c. Databricks Free Edition を使う場合
databricks auth login -p w01 --host https://{WorkspaceURL}/
terraform -chdir='terraform/03-databricks-workspace-free' init
terraform -chdir='terraform/03-databricks-workspace-free' apply -var 'dbx_profile=w01'

# d. サーバーレス専用ワークスペースを使う場合
# NAT ゲートウェイ等のクラシック計算資源を作らないため、料金が発生しにくい
terraform -chdir='terraform/03-databricks-workspace' init
terraform -chdir='terraform/03-databricks-workspace' apply
```

## 4. VPC Peering
作成したワークスペース VPC と普段の作業場 VPC をピアリングする。

```ini
# Rename: terraform/04-aws-post/terraform.tfvars.sample
# -> terraform.tfvars
aws_vpcid_dbxworkspace = "{ワークスペースのVPCID}"
aws_vpcid_external = "{外部VPCのVPCID}"
aws_rtbid_cluster = "{ワークスペースのクラスター用ルートテーブルID}"
aws_rtbid_external = "{外部VPCのルートテーブルID}"
aws_sgid_dbxcluster = "{ワークスペースのクラスター用セキュリティグループID}"
```

```sh
terraform -chdir='terraform/04-aws-post' init
terraform -chdir='terraform/04-aws-post' apply
```

## 5. Extra (任意)

```sh
## Launch Kafka
terraform -chdir='terraform/05-aws-kafka' apply
```

## 6. Cleanup

```sh
terraform -chdir='terraform/05-aws-kafka' destroy
terraform -chdir='terraform/04-aws-post' destroy
terraform -chdir='terraform/03-databricks-workspace-free' destroy -var 'dbx_profile=w01'

terraform -chdir='terraform/03-databricks-workspace-classic' destroy
terraform -chdir='terraform/03-databricks-workspace-cmvpc' destroy
terraform -chdir='terraform/03-databricks-workspace' destroy

terraform -chdir='terraform/02-databricks-regional-cmvpc' destroy
terraform -chdir='terraform/02-databricks-regional' destroy
terraform -chdir='terraform/02-databricks-global' destroy
terraform -chdir='terraform/01-aws-regional-cmvpc' destroy
terraform -chdir='terraform/01-aws-regional' destroy
terraform -chdir='terraform/01-aws-global' destroy
```
