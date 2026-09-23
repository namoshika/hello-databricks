terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.58.0"
    }
  }
  backend "local" {
    path = "../tfstates/02-databricks-global.tfstate"
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "dbx_profile" {
  type    = string
  default = "DEFAULT"
}
variable "dbx_account_id" { type = string }
variable "dbx_groupname_admin" {
  type    = string
  default = "admin"
}

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
data "terraform_remote_state" "aws_global" {
  backend = "local"
  config  = { path = "../tfstates/01-aws-global.tfstate" }
}
locals {
  aws_iamrole_arn_credential_basic = data.terraform_remote_state.aws_global.outputs.aws_iamrole_arn_credential_basic
  aws_iamrole_arn_credential_cmvpc = data.terraform_remote_state.aws_global.outputs.aws_iamrole_arn_credential_cmvpc
}

# ----------------------------
# Account Scope - User, Service Principal, Group
# ----------------------------
resource "databricks_service_principal" "terraform" {
  provider                 = databricks.mws
  display_name             = "terraform"
  force                    = true
  disable_as_user_deletion = false
}
resource "databricks_service_principal_role" "terraform" {
  provider             = databricks.mws
  service_principal_id = databricks_service_principal.terraform.id
  role                 = "account_admin"
}
resource "databricks_service_principal_secret" "terraform" {
  provider             = databricks.mws
  service_principal_id = databricks_service_principal.terraform.id
}
resource "databricks_group" "admin" {
  provider     = databricks.mws
  display_name = var.dbx_groupname_admin
  force        = true
}
resource "databricks_group_member" "terraform" {
  provider  = databricks.mws
  group_id  = databricks_group.admin.id
  member_id = databricks_service_principal.terraform.id
}

# ----------------------------
# Account Scope - Cloud Resource
# ----------------------------
resource "databricks_mws_credentials" "base_basic" {
  provider         = databricks.mws
  credentials_name = "dbx-iamrole-base-basic"
  role_arn         = local.aws_iamrole_arn_credential_basic
}
resource "databricks_mws_credentials" "base_cmvpc" {
  provider         = databricks.mws
  credentials_name = "dbx-iamrole-base-cmvpc"
  role_arn         = local.aws_iamrole_arn_credential_cmvpc
}

# ----------------------------
# Output
# ----------------------------
output "databricks_account_id" {
  value = var.dbx_account_id
}
output "databricks_client_id" {
  value = databricks_service_principal.terraform.application_id
}
output "databricks_client_secret" {
  value     = databricks_service_principal_secret.terraform.secret
  sensitive = true
}
output "databricks_credentials_id_basic" {
  value = databricks_mws_credentials.base_basic.credentials_id
}
output "databricks_credentials_id_cmvpc" {
  value = databricks_mws_credentials.base_cmvpc.credentials_id
}
output "databricks_groupname_admin" {
  value = databricks_group.admin.display_name
}
