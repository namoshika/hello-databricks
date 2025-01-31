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
# Rename: terraform/01-aws-base/terraform.tfvars.sample
# -> terraform.tfvars
external_aws_s3_bucketname_storage = "{入力データ用 S3 BucketName}"
aws_s3_bucketname_storage = "{ワークスペースカタログ用 S3 BucketName}"
databricks_account_id = "{DatabricksのアカウントID}"

# Rename: terraform/02-databricks-base/terraform.tfvars.sample
# -> terraform.tfvars
aws_region = "{デプロイ先 AWS リージョン}"
databricks_account_id = "{DatabricksのアカウントID}"

# Rename: terraform/03-databricks-workspace-basic/terraform.tfvars.sample
# -> terraform.tfvars
aws_region = "{デプロイ先 AWS リージョン}"
databricks_usermail_admin = "{管理者アカウントのメールアドレス}"
databricks_workspace_name = "{ワークスペースの名前}"
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
# AWS の設定を行う。IAMロールの自己仮定の都合で2回デプロイする
terraform -chdir='terraform/01-aws-base' init
terraform -chdir='terraform/01-aws-base' apply -var 'is_firststep=true'
terraform -chdir='terraform/01-aws-base' apply

# Databricks のアカウントコンソールを設定
terraform -chdir='terraform/02-databricks-base' init
terraform -chdir='terraform/02-databricks-base' apply

# ----------------------------
# 任意: 顧客管理 VPC を使う場合
# ----------------------------
# AWS の設定を行う
terraform -chdir='terraform/01-aws-network' init
terraform -chdir='terraform/01-aws-network' apply

# Databricks のアカウントコンソールを設定
terraform -chdir='terraform/02-databricks-network-cmvpc' init
terraform -chdir='terraform/02-databricks-network-cmvpc' apply
```

## 3. Setup Workspace
ワークスペースを作成する際に都度実行する。  
作成すると AWS 上に NAT ゲートウェイが生成され、常に AWS の使用料金が発生する。そのため、使わない時は削除しておくと良い。

```sh
# Databricks のワークスペースを作成
# a. Databricks 管理 VPC を使う場合
terraform -chdir='terraform/03-databricks-workspace-basic' init
terraform -chdir='terraform/03-databricks-workspace-basic' apply

# b. 顧客管理 VPC を使う場合
terraform -chdir='terraform/03-databricks-workspace-cmvpc' init
terraform -chdir='terraform/03-databricks-workspace-cmvpc' apply

# Databricks のワークスペースへ資材を配置
databricks auth login -p w01 --host https://{WorkspaceURL}/
terraform -chdir='terraform/04-databricks-home' init
terraform -chdir='terraform/04-databricks-home' apply -var 'profile=w01'

## 4. Launch Kafka
terraform -chdir='terraform/04-external-kafka' apply

```

## 4. Cleanup

```sh
terraform -chdir='terraform/04-external-kafka' destroy
terraform -chdir='terraform/04-databricks-home' destroy -var 'profile=w01'

terraform -chdir='terraform/03-databricks-workspace-basic' destroy
terraform -chdir='terraform/03-databricks-workspace-cmvpc' destroy

terraform -chdir='terraform/02-databricks-network-cmvpc' destroy
terraform -chdir='terraform/02-databricks-base' destroy
terraform -chdir='terraform/01-aws-network' destroy
terraform -chdir='terraform/01-aws-base' destroy

```
