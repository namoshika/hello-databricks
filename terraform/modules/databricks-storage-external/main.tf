terraform {
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      version               = "1.58.0"
      configuration_aliases = [databricks.workspace]
    }
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "aws_iam_role_arn" { type = string }
variable "aws_s3_bucketname" { type = string }
variable "aws_s3_prefix_uv" {
  type    = string
  default = "/data/"
}
variable "databricks_uv_mountpoint_catalog" { type = string }
variable "databricks_uv_mountpoint_schema" { type = string }
variable "databricks_principal_owner" { type = string }

# ----------------------------
# External Storage
# ----------------------------
resource "databricks_storage_credential" "ex" {
  provider = databricks.workspace
  name     = var.aws_s3_bucketname
  owner    = var.databricks_principal_owner
  aws_iam_role { role_arn = var.aws_iam_role_arn }
}
resource "databricks_external_location" "ex" {
  provider        = databricks.workspace
  name            = var.aws_s3_bucketname
  url             = "s3://${var.aws_s3_bucketname}"
  owner           = var.databricks_principal_owner
  credential_name = databricks_storage_credential.ex.id
}
resource "databricks_grants" "cred" {
  provider           = databricks.workspace
  storage_credential = databricks_storage_credential.ex.id
  grant {
    # 全てのユーザへ外部ストレージへの全権限を与える
    # 全てのユーザを含むグループとして account users (表示名: All account users) が既定で作成されている
    # https://registry.terraform.io/providers/databricks/databricks/latest/docs/guides/unity-catalog
    principal  = "account users"
    privileges = ["ALL_PRIVILEGES"]
  }
}
resource "databricks_grants" "loc" {
  provider          = databricks.workspace
  external_location = databricks_external_location.ex.id
  grant {
    # 全てのユーザへ外部ストレージへの全権限を与える
    # 全てのユーザを含むグループとして account users (表示名: All account users) が既定で作成されている
    # https://registry.terraform.io/providers/databricks/databricks/latest/docs/guides/unity-catalog
    principal  = "account users"
    privileges = ["ALL_PRIVILEGES"]
  }
}

# ----------------------------
# Unity Volume
# ----------------------------
resource "databricks_volume" "ex" {
  depends_on       = [databricks_external_location.ex]
  provider         = databricks.workspace
  name             = var.aws_s3_bucketname
  catalog_name     = var.databricks_uv_mountpoint_catalog
  schema_name      = var.databricks_uv_mountpoint_schema
  owner            = var.databricks_principal_owner
  volume_type      = "EXTERNAL"
  storage_location = "s3://${var.aws_s3_bucketname}${var.aws_s3_prefix_uv}"
}
resource "databricks_grants" "vol" {
  provider = databricks.workspace
  volume   = databricks_volume.ex.id
  grant {
    # 全てのユーザへ外部ストレージへの全権限を与える
    # 全てのユーザを含むグループとして account users (表示名: All account users) が既定で作成されている
    # https://registry.terraform.io/providers/databricks/databricks/latest/docs/guides/unity-catalog
    principal  = "account users"
    privileges = ["ALL_PRIVILEGES"]
  }
}
