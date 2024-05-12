terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.58.0"
    }
  }
  backend "local" {
    path = "../tfstates/04-databricks-home.tfstate"
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "profile" { type = string }

# ----------------------------
# Provider
# ----------------------------
provider "databricks" {
  alias   = "workspace"
  host    = local.databricks_workspace_url
  profile = var.profile
}

# ----------------------------
# Data
# ----------------------------
data "databricks_current_user" "me" {
  provider = databricks.workspace
}
data "terraform_remote_state" "base" {
  backend = "local"
  config  = { path = "../tfstates/01-base.tfstate" }
}
data "terraform_remote_state" "workspace" {
  backend = "local"
  config  = { path = "../tfstates/03-databricks-workspace-basic.tfstate" }
}
locals {
  aws_s3_bucketname_input   = data.terraform_remote_state.base.outputs.aws_s3_bucketname_input
  databricks_workspace_url  = data.terraform_remote_state.workspace.outputs.databricks_workspace_url
  databricks_workspace_name = data.terraform_remote_state.workspace.outputs.databricks_workspace_name
}

# ----------------------------
# ワークスペースへ資材を配置
# ----------------------------
resource "terraform_data" "run_script" {
  triggers_replace = [
    local.databricks_workspace_url
  ]
  provisioner "local-exec" {
    command = "databricks workspace import-dir -p ${var.profile} '../../workspace' '${data.databricks_current_user.me.home}'"
  }
}

# ----------------------------
# Delta Live Table を設定
# ----------------------------
resource "databricks_pipeline" "sample_pipeline" {
  provider      = databricks.workspace
  depends_on    = [terraform_data.run_script]
  name          = "sample-pipeline"
  catalog       = local.databricks_workspace_name
  target        = "default"
  continuous    = false
  development   = true
  serverless    = true
  configuration = { "DATA_BUCKET_NAME" = local.aws_s3_bucketname_input }

  library {
    notebook { path = "${data.databricks_current_user.me.home}/sample_helloworld/02. DeltaLiveTable" }
  }
}
