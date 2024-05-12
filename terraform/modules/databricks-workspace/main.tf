terraform {
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      version               = "1.58.0"
      configuration_aliases = [databricks.mws]
    }
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "aws_region" { type = string }
variable "aws_iam_role_arn_workspace" { type = string }
variable "aws_s3_bucketname_workspace" { type = string }
variable "databricks_account_id" { type = string }
variable "databricks_client_id" { type = string }
variable "databricks_client_secret" {
  type      = string
  sensitive = true
}
variable "databricks_credentials_id" { type = string }
variable "databricks_metastore_id" { type = string }
variable "databricks_storage_configuration_id" { type = string }
variable "databricks_principal_owner" { type = string }
variable "databricks_workspace_name" { type = string }

# ----------------------------
# Account Scope - Workspace
# ----------------------------
resource "databricks_mws_workspaces" "sample" {
  provider                 = databricks.mws
  account_id               = var.databricks_account_id
  aws_region               = var.aws_region
  credentials_id           = var.databricks_credentials_id
  storage_configuration_id = var.databricks_storage_configuration_id
  workspace_name           = var.databricks_workspace_name
}
resource "databricks_metastore_assignment" "base" {
  provider             = databricks.mws
  metastore_id         = var.databricks_metastore_id
  workspace_id         = databricks_mws_workspaces.sample.workspace_id
  default_catalog_name = databricks_mws_workspaces.sample.workspace_name
}

# ----------------------------
# Workspace Scope - Provider
# ----------------------------
provider "databricks" {
  alias         = "workspace"
  host          = databricks_mws_workspaces.sample.workspace_url
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

# ----------------------------
# Workspace Scope - Catalog
# ----------------------------
resource "databricks_storage_credential" "workspace" {
  force_destroy  = true
  depends_on     = [databricks_metastore_assignment.base]
  provider       = databricks.workspace
  name           = databricks_mws_workspaces.sample.workspace_name
  owner          = var.databricks_principal_owner
  isolation_mode = "ISOLATION_MODE_ISOLATED"
  aws_iam_role { role_arn = var.aws_iam_role_arn_workspace }
}
resource "databricks_external_location" "workspace" {
  force_destroy   = true
  depends_on      = [databricks_metastore_assignment.base]
  provider        = databricks.workspace
  name            = databricks_mws_workspaces.sample.workspace_name
  url             = "s3://${var.aws_s3_bucketname_workspace}/unity-catalog/${databricks_mws_workspaces.sample.workspace_id}"
  owner           = var.databricks_principal_owner
  credential_name = databricks_storage_credential.workspace.id
  isolation_mode  = "ISOLATION_MODE_ISOLATED"
}
resource "databricks_catalog" "base" {
  force_destroy  = true
  depends_on     = [databricks_metastore_assignment.base, databricks_external_location.workspace]
  provider       = databricks.workspace
  name           = databricks_mws_workspaces.sample.workspace_name
  owner          = var.databricks_principal_owner
  storage_root   = "s3://${var.aws_s3_bucketname_workspace}/unity-catalog/${databricks_mws_workspaces.sample.workspace_id}"
  isolation_mode = "ISOLATED"
}
resource "databricks_schema" "base" {
  force_destroy = true
  provider      = databricks.workspace
  catalog_name  = databricks_catalog.base.id
  owner         = var.databricks_principal_owner
  name          = "default"
}
resource "databricks_grant" "metastore" {
  depends_on = [databricks_metastore_assignment.base]
  provider   = databricks.workspace
  metastore  = var.databricks_metastore_id
  principal  = var.databricks_principal_owner
  privileges = [
    "CREATE_CATALOG", "CREATE_CONNECTION", "CREATE_EXTERNAL_LOCATION",
    "CREATE_PROVIDER", "CREATE_RECIPIENT", "CREATE_SHARE",
    "CREATE_STORAGE_CREDENTIAL"
  ]
}
resource "databricks_grant" "catalog" {
  provider = databricks.workspace
  catalog  = databricks_catalog.base.name
  # 全てのユーザを含むグループとして account users (表示名: All account users) が既定で作成されている
  # https://registry.terraform.io/providers/databricks/databricks/latest/docs/guides/unity-catalog
  principal  = "account users"
  privileges = ["USE CATALOG", "USE_SCHEMA"]
}

# ----------------------------
# Output
# ----------------------------
output "databricks_workspace_url" {
  value = databricks_mws_workspaces.sample.workspace_url
}
output "databricks_workspace_id" {
  value = databricks_mws_workspaces.sample.workspace_id
}
