terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.58.0"
    }
  }
  backend "local" {
    path = "../tfstates/03-databricks-workspace-free.tfstate"
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "aws_iamrole_arn_storage_external" { type = string }
variable "aws_s3_bucketname_storage_external" { type = string }
variable "databricks_profile" {
  type    = string
  default = null
}
variable "databricks_catalog_name" {
  type    = string
  default = "workspace"
}

# ----------------------------
# Provider
# ----------------------------
provider "databricks" {
  alias   = "workspace"
  profile = var.databricks_profile
}

# ----------------------------
# Workspace Scope - ワークスペースカタログへ入力バケットをマウント
# ----------------------------
module "external_storage" {
  source                           = "../modules/databricks-storage-external"
  aws_iam_role_arn                 = var.aws_iamrole_arn_storage_external
  aws_s3_bucketname                = var.aws_s3_bucketname_storage_external
  databricks_principal_owner       = null
  databricks_uv_mountpoint_catalog = var.databricks_catalog_name
  databricks_uv_mountpoint_schema  = "default"
  providers = {
    databricks.workspace = databricks.workspace
  }
}
