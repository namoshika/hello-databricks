terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.58.0"
    }
  }
  backend "local" {
    path = "../tfstates/02-databricks-network-cmvpc.tfstate"
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}
variable "databricks_profile" {
  type    = string
  default = "DEFAULT"
}
variable "databricks_account_id" { type = string }

# ----------------------------
# Provider
# ----------------------------
provider "databricks" {
  alias      = "mws"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  profile    = var.databricks_profile
}

# ----------------------------
# Data
# ----------------------------
data "terraform_remote_state" "base" {
  backend = "local"
  config  = { path = "../tfstates/01-aws-base.tfstate" }
}
data "terraform_remote_state" "network" {
  backend = "local"
  config  = { path = "../tfstates/01-aws-network-cmvpc.tfstate" }
}
locals {
  aws_vpc_id                    = data.terraform_remote_state.network.outputs.aws_vpc_id
  aws_vpc_name                  = data.terraform_remote_state.network.outputs.aws_vpc_name
  aws_subnet_id_cluster_a       = data.terraform_remote_state.network.outputs.aws_subnet_id_cluster_a
  aws_subnet_id_cluster_b       = data.terraform_remote_state.network.outputs.aws_subnet_id_cluster_b
  aws_securitygroup_id_cluster  = data.terraform_remote_state.network.outputs.aws_securitygroup_id_cluster
  aws_endpoint_id_scc           = data.terraform_remote_state.network.outputs.aws_endpoint_id_scc
  aws_endpoint_name_scc         = data.terraform_remote_state.network.outputs.aws_endpoint_name_scc
  aws_endpoint_id_internal      = data.terraform_remote_state.network.outputs.aws_endpoint_id_internal
  aws_endpoint_name_internal    = data.terraform_remote_state.network.outputs.aws_endpoint_name_internal
}

# ----------------------------
# Account Scope - Cloud Resource
# ----------------------------
resource "databricks_mws_vpc_endpoint" "scc" {
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  region              = var.aws_region
  aws_vpc_endpoint_id = local.aws_endpoint_id_scc
  vpc_endpoint_name   = local.aws_endpoint_name_scc
}
resource "databricks_mws_vpc_endpoint" "workspace" {
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  region              = var.aws_region
  aws_vpc_endpoint_id = local.aws_endpoint_id_internal
  vpc_endpoint_name   = local.aws_endpoint_name_internal
}
resource "databricks_mws_networks" "cmvpc" {
  provider           = databricks.mws
  account_id         = var.databricks_account_id
  network_name       = local.aws_vpc_name
  vpc_id             = local.aws_vpc_id
  subnet_ids         = [local.aws_subnet_id_cluster_a, local.aws_subnet_id_cluster_b]
  security_group_ids = [local.aws_securitygroup_id_cluster]
  vpc_endpoints {
    dataplane_relay = [databricks_mws_vpc_endpoint.scc.vpc_endpoint_id]
    rest_api        = [databricks_mws_vpc_endpoint.workspace.vpc_endpoint_id]
  }
}
resource "databricks_mws_private_access_settings" "cmvpc" {
  provider                     = databricks.mws
  region                       = var.aws_region
  public_access_enabled        = true
  private_access_settings_name = "dbx-privateaccess-cmvpc"
  private_access_level         = "ENDPOINT"
  allowed_vpc_endpoint_ids     = [databricks_mws_vpc_endpoint.workspace.vpc_endpoint_id]
}

# ----------------------------
# Output
# ----------------------------
output "databricks_networks_id" {
  value = databricks_mws_networks.cmvpc.network_id
}
output "databricks_private_access_settings_id" {
  value = databricks_mws_private_access_settings.cmvpc.private_access_settings_id
}