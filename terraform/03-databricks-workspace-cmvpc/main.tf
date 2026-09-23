terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.58.0"
    }
  }
  backend "local" {
    path = "../tfstates/03-databricks-workspace-cmvpc.tfstate"
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}
variable "dbx_workspace_name" {
  type    = string
  default = "sample-workspace-cmvpc"
}
variable "dbx_usermail_admin" { type = string }

# ----------------------------
# Data (1/2)
# ----------------------------
data "terraform_remote_state" "aws_global" {
  backend = "local"
  config  = { path = "../tfstates/01-aws-global.tfstate" }
}
data "terraform_remote_state" "aws_regional" {
  backend = "local"
  config  = { path = "../tfstates/01-aws-regional.tfstate" }
}
data "terraform_remote_state" "databricks_global" {
  backend = "local"
  config  = { path = "../tfstates/02-databricks-global.tfstate" }
}
data "terraform_remote_state" "databricks_regional" {
  backend = "local"
  config  = { path = "../tfstates/02-databricks-regional.tfstate" }
}
data "terraform_remote_state" "databricks_network" {
  backend = "local"
  config  = { path = "../tfstates/02-databricks-regional-cmvpc.tfstate" }
}
locals {
  aws_iamrole_arn_storage_databricks    = data.terraform_remote_state.aws_regional.outputs.aws_iamrole_arn_storage
  aws_instanceprofile_arn_cluster       = data.terraform_remote_state.aws_global.outputs.aws_instanceprofile_arn_cluster
  aws_s3_bucketname_storage_databricks  = data.terraform_remote_state.aws_regional.outputs.aws_s3_bucketname_storage
  databricks_account_id                 = data.terraform_remote_state.databricks_global.outputs.databricks_account_id
  databricks_client_id                  = data.terraform_remote_state.databricks_global.outputs.databricks_client_id
  databricks_client_secret              = data.terraform_remote_state.databricks_global.outputs.databricks_client_secret
  databricks_credentials_id_cmvpc       = data.terraform_remote_state.databricks_global.outputs.databricks_credentials_id_cmvpc
  databricks_groupname_admin            = data.terraform_remote_state.databricks_global.outputs.databricks_groupname_admin
  databricks_metastore_id               = data.terraform_remote_state.databricks_regional.outputs.databricks_metastore_id
  databricks_storage_configuration_id   = data.terraform_remote_state.databricks_regional.outputs.databricks_storage_configuration_id
  databricks_networks_id                = data.terraform_remote_state.databricks_network.outputs.databricks_networks_id
  databricks_private_access_settings_id = data.terraform_remote_state.databricks_network.outputs.databricks_private_access_settings_id
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
  user_name = var.dbx_usermail_admin
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
  source                                = "../modules/databricks-workspace"
  aws_region                            = var.aws_region
  aws_iamrole_arn_storage               = local.aws_iamrole_arn_storage_databricks
  aws_s3_bucketname_storage             = local.aws_s3_bucketname_storage_databricks
  aws_instanceprofile_arn_cluster       = local.aws_instanceprofile_arn_cluster
  databricks_account_id                 = local.databricks_account_id
  databricks_client_id                  = local.databricks_client_id
  databricks_client_secret              = local.databricks_client_secret
  databricks_credentials_id             = local.databricks_credentials_id_cmvpc
  databricks_metastore_id               = local.databricks_metastore_id
  databricks_storage_configuration_id   = local.databricks_storage_configuration_id
  databricks_principal_owner            = local.databricks_groupname_admin
  databricks_workspace_name             = var.dbx_workspace_name
  databricks_network_id                 = local.databricks_networks_id
  databricks_private_access_settings_id = local.databricks_private_access_settings_id
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
# Output
# ----------------------------
output "databricks_workspace_name" {
  value = var.dbx_workspace_name
}
output "databricks_workspace_url" {
  value = module.workspace.databricks_workspace_url
}
