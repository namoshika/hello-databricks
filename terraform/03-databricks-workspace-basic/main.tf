terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.58.0"
    }
  }
  backend "local" {
    path = "../tfstates/03-databricks-workspace-basic.tfstate"
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}
variable "databricks_workspace_name" {
  type    = string
  default = "sample-workspace"
}
variable "databricks_usermail_admin" { type = string }

# ----------------------------
# Data (1/2)
# ----------------------------
data "terraform_remote_state" "base" {
  backend = "local"
  config  = { path = "../tfstates/01-base.tfstate" }
}
data "terraform_remote_state" "databricks_base" {
  backend = "local"
  config  = { path = "../tfstates/02-databricks-base.tfstate" }
}
locals {
  aws_iam_role_arn_input              = data.terraform_remote_state.base.outputs.aws_iam_role_arn_input
  aws_iam_role_arn_workspace          = data.terraform_remote_state.base.outputs.aws_iam_role_arn_workspace
  aws_s3_bucketname_input             = data.terraform_remote_state.base.outputs.aws_s3_bucketname_input
  aws_s3_bucketname_workspace         = data.terraform_remote_state.base.outputs.aws_s3_bucketname_workspace
  databricks_account_id               = data.terraform_remote_state.databricks_base.outputs.databricks_account_id
  databricks_client_id                = data.terraform_remote_state.databricks_base.outputs.databricks_client_id
  databricks_client_secret            = data.terraform_remote_state.databricks_base.outputs.databricks_client_secret
  databricks_credentials_id           = data.terraform_remote_state.databricks_base.outputs.databricks_credentials_id
  databricks_groupname_admin          = data.terraform_remote_state.databricks_base.outputs.databricks_groupname_admin
  databricks_metastore_id             = data.terraform_remote_state.databricks_base.outputs.databricks_metastore_id
  databricks_storage_configuration_id = data.terraform_remote_state.databricks_base.outputs.databricks_storage_configuration_id
}

# ----------------------------
# Account Scope - Provider
# ----------------------------
provider "databricks" {
  alias         = "mws"
  host          = "https://accounts.cloud.databricks.com"
  account_id    = local.databricks_account_id
  client_id     = local.databricks_client_id
  client_secret = local.databricks_client_secret
}

# ----------------------------
# Data (2/2)
# ----------------------------
data "databricks_user" "admin" {
  provider  = databricks.mws
  user_name = var.databricks_usermail_admin
}
data "databricks_group" "admin" {
  provider     = databricks.mws
  display_name = local.databricks_groupname_admin
}

# ----------------------------
# Account Scope - ワークスペースの管理ユーザを管理者グループへ追加
# ----------------------------
resource "databricks_group_member" "admin" {
  provider  = databricks.mws
  group_id  = data.databricks_group.admin.id
  member_id = data.databricks_user.admin.id
}

# ----------------------------
# Account Scope - ワークスペースを作成
# ----------------------------
module "workspace" {
  source                              = "../modules/databricks-workspace"
  aws_region                          = var.aws_region
  aws_iam_role_arn_workspace          = local.aws_iam_role_arn_workspace
  aws_s3_bucketname_workspace         = local.aws_s3_bucketname_workspace
  databricks_account_id               = local.databricks_account_id
  databricks_client_id                = local.databricks_client_id
  databricks_client_secret            = local.databricks_client_secret
  databricks_credentials_id           = local.databricks_credentials_id
  databricks_metastore_id             = local.databricks_metastore_id
  databricks_storage_configuration_id = local.databricks_storage_configuration_id
  databricks_principal_owner          = local.databricks_groupname_admin
  databricks_workspace_name           = var.databricks_workspace_name
  providers = {
    databricks.mws = databricks.mws
  }
}
resource "time_sleep" "wait" {
  depends_on      = [module.workspace]
  create_duration = "20s"
}
resource "databricks_mws_permission_assignment" "admin" {
  depends_on   = [time_sleep.wait]
  provider     = databricks.mws
  workspace_id = module.workspace.databricks_workspace_id
  principal_id = data.databricks_user.admin.id
  permissions  = ["ADMIN"]
}

# ----------------------------
# Workspace Scope - Provider
# ----------------------------
provider "databricks" {
  alias         = "workspace"
  host          = module.workspace.databricks_workspace_url
  client_id     = local.databricks_client_id
  client_secret = local.databricks_client_secret
}

# ----------------------------
# Workspace Scope - ワークスペースカタログへ入力バケットをマウント
# ----------------------------
module "external_storage" {
  source                           = "../modules/databricks-storage-external"
  depends_on                       = [module.workspace]
  aws_iam_role_arn_external        = local.aws_iam_role_arn_input
  aws_s3_bucketname_external       = local.aws_s3_bucketname_input
  databricks_principal_owner       = local.databricks_groupname_admin
  databricks_uv_mountpoint_catalog = var.databricks_workspace_name
  databricks_uv_mountpoint_schema  = "default"
  providers = {
    databricks.workspace = databricks.workspace
  }
}

# ----------------------------
# Output
# ----------------------------
output "databricks_workspace_name" {
  value = var.databricks_workspace_name
}
output "databricks_workspace_url" {
  value = module.workspace.databricks_workspace_url
}
