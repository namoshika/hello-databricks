terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.58.0"
    }
  }
  backend "local" {
    path = "../tfstates/02-databricks-regional.tfstate"
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}
variable "dbx_profile" {
  type    = string
  default = "DEFAULT"
}
variable "dbx_account_id" { type = string }

# ----------------------------
# Provider
# ----------------------------
provider "databricks" {
  alias      = "mws"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.dbx_account_id
  profile    = var.dbx_profile
}

# ----------------------------
# Data
# ----------------------------
data "terraform_remote_state" "aws_regional" {
  backend = "local"
  config  = { path = "../tfstates/01-aws-regional.tfstate" }
}
locals {
  aws_s3_bucketname_storage = data.terraform_remote_state.aws_regional.outputs.aws_s3_bucketname_storage
  databricks_metastore_name = replace("metastore_aws_${var.aws_region}", "-", "_")
}

# ----------------------------
# Region Scope - Catalog
# ----------------------------
resource "databricks_metastore" "base" {
  provider = databricks.mws
  name     = local.databricks_metastore_name
  # 管理者を指定しないメタストアのオーナーとして System user を指定する
  # システムユーザとして System user (表示名: System user) が既定で作成されている
  owner         = "System user"
  region        = var.aws_region
  force_destroy = true
}

# ----------------------------
# Region Scope - Cloud Resource
# ----------------------------
resource "databricks_mws_storage_configurations" "base" {
  provider                   = databricks.mws
  account_id                 = var.dbx_account_id
  storage_configuration_name = local.aws_s3_bucketname_storage
  bucket_name                = local.aws_s3_bucketname_storage
}

# ----------------------------
# Output
# ----------------------------
output "databricks_metastore_id" {
  value = databricks_metastore.base.metastore_id
}
output "databricks_storage_configuration_id" {
  value = databricks_mws_storage_configurations.base.storage_configuration_id
}
