terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.75.0"
    }
  }
  backend "local" {
    path = "../tfstates/01-aws-regional.tfstate"
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "dbx_account_id" { type = string }
variable "aws_profile" {
  type    = string
  default = "default"
}
variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}
variable "aws_s3_bucketname_workspace" { type = string }
variable "is_firststep" {
  type    = bool
  default = false
}
locals {
  tags = { Service = "hello-databricks" }
}

# ----------------------------
# Provider
# ----------------------------
provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

# ----------------------------
# AWS Cfn Databricks Stack
# ----------------------------
resource "aws_cloudformation_stack" "databricks_storage" {
  name          = "dbx-workspace-storage"
  template_body = file("../../cloudformation/databricks-workspace-storage.cf.yaml")
  parameters = {
    DatabricksAccountId = var.dbx_account_id,
    S3BucketName        = var.aws_s3_bucketname_workspace
    IsFirstStep         = var.is_firststep ? "True" : "False",
  }
  tags         = local.tags
  capabilities = ["CAPABILITY_NAMED_IAM"]
}

# ----------------------------
# Output databricks
# ----------------------------
output "aws_iamrole_arn_storage" {
  value = aws_cloudformation_stack.databricks_storage.outputs["IamRoleArn"]
}
output "aws_s3_bucketname_storage" {
  value = aws_cloudformation_stack.databricks_storage.outputs["S3BucketName"]
}
