#!/bin/bash

DATABRICKS_ACCOUNT_ID='...'
DATABRICKS_BUCKET_NAME_WORKSPACE='...'
DATABRICKS_BUCKET_NAME_INPUT="..."

# -------------------------------------
# ベーススタック (Basic)
# -------------------------------------
aws cloudformation deploy \
    --stack-name 'databricks-base-basic' \
    --template-file 'cloudformation/databricks-base-basic.cf.yaml' \
    --parameter-overrides DatabricksAccountId="$DATABRICKS_ACCOUNT_ID" \
    --capabilities CAPABILITY_NAMED_IAM

# -------------------------------------
# ベーススタック (Customer Managed VPC)
# -------------------------------------
aws cloudformation deploy \
    --stack-name 'databricks-base-cmvpc' \
    --template-file 'cloudformation/databricks-base-cmvpc.cf.yaml' \
    --parameter-overrides DatabricksAccountId="$DATABRICKS_ACCOUNT_ID" \
    --capabilities CAPABILITY_NAMED_IAM

aws cloudformation deploy \
    --stack-name 'databricks-network-cmvpc' \
    --template-file 'cloudformation/databricks-network-cmvpc.cf.yaml' \
    --parameter-overrides DatabricksWorkspaceName="wk1" \
    --capabilities CAPABILITY_NAMED_IAM

# -------------------------------------
# ワークスペース
# -------------------------------------
aws cloudformation deploy \
    --stack-name 'databricks-storage-workspace' \
    --template-file 'cloudformation/databricks-storage-workspace.cf.yaml' \
    --parameter-overrides DatabricksAccountId="$DATABRICKS_ACCOUNT_ID" S3BucketName="$DATABRICKS_BUCKET_NAME_WORKSPACE" \
    --capabilities CAPABILITY_NAMED_IAM

# IAM Role を自己仮定型にするために再デプロイを行う
aws cloudformation deploy \
    --stack-name 'databricks-storage-workspace' \
    --template-file 'cloudformation/databricks-storage-workspace.cf.yaml' \
    --parameter-overrides DatabricksAccountId="$DATABRICKS_ACCOUNT_ID" S3BucketName="$DATABRICKS_BUCKET_NAME_WORKSPACE" IsFirstStep="False" \
    --capabilities CAPABILITY_NAMED_IAM

# -------------------------------------
# 外部ストレージ
# -------------------------------------
aws cloudformation deploy \
    --stack-name 'databricks-storage-external-01' \
    --template-file 'cloudformation/databricks-storage-external.cf.yaml' \
    --parameter-overrides DatabricksAccountId="$DATABRICKS_ACCOUNT_ID" S3BucketName="$DATABRICKS_BUCKET_NAME_INPUT" IamRoleName="databricks-iamrole-external-01" \
    --capabilities CAPABILITY_NAMED_IAM

aws cloudformation deploy \
    --stack-name 'databricks-storage-external-01' \
    --template-file 'cloudformation/databricks-storage-external.cf.yaml' \
    --parameter-overrides DatabricksAccountId="$DATABRICKS_ACCOUNT_ID" S3BucketName="$DATABRICKS_BUCKET_NAME_INPUT" IamRoleName="databricks-iamrole-external-01" IsFirstStep="False" \
    --capabilities CAPABILITY_NAMED_IAM
