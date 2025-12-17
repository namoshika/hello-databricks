terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.75.0"
    }
  }
  backend "local" {
    path = "../tfstates/01-aws-base.tfstate"
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "databricks_account_id" { type = string }
variable "aws_profile" {
  type    = string
  default = "default"
}
variable "aws_s3_bucketname_workspace" { type = string }
variable "aws_s3_bucketname_input" { type = string }
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
}

# ----------------------------
# AWS Cfn Databricks Stack
# ----------------------------
resource "aws_cloudformation_stack" "databricks_base" {
  name          = "dbx-base"
  template_body = file("../../cloudformation/databricks-base.cf.yaml")
  parameters    = { DatabricksAccountId = var.databricks_account_id }
  tags          = local.tags
  capabilities  = ["CAPABILITY_NAMED_IAM"]
}
resource "aws_cloudformation_stack" "databricks_storage" {
  name          = "dbx-workspace-storage"
  template_body = file("../../cloudformation/databricks-workspace-storage.cf.yaml")
  parameters = {
    DatabricksAccountId = var.databricks_account_id,
    S3BucketName        = var.aws_s3_bucketname_workspace
    IsFirstStep         = var.is_firststep ? "True" : "False",
  }
  tags         = local.tags
  capabilities = ["CAPABILITY_NAMED_IAM"]
}

# ----------------------------
# AWS Cfn External Stack
# ----------------------------
resource "aws_cloudformation_stack" "external_storage" {
  name          = "dbx-external-storage"
  template_body = file("../../cloudformation/external-storage.cf.yaml")
  parameters = {
    DatabricksAccountId = var.databricks_account_id,
    S3BucketName        = var.aws_s3_bucketname_input
    IsFirstStep         = var.is_firststep ? "True" : "False",
  }
  tags         = local.tags
  capabilities = ["CAPABILITY_NAMED_IAM"]
}

# ----------------------------
# Output databricks
# ----------------------------
output "aws_iamrole_arn_credential_basic" {
  value = aws_cloudformation_stack.databricks_base.outputs["IAMRoleForCredentialBasic"]
}
output "aws_iamrole_arn_credential_cmvpc" {
  value = aws_cloudformation_stack.databricks_base.outputs["IAMRoleForCredentialCmvpc"]
}
output "aws_iamrole_arn_storage" {
  value = aws_cloudformation_stack.databricks_storage.outputs["IamRoleArn"]
}
output "aws_s3_bucketname_storage" {
  value = aws_cloudformation_stack.databricks_storage.outputs["S3BucketName"]
}
output "aws_instanceprofile_arn_cluster" {
  value = aws_cloudformation_stack.databricks_base.outputs["InstanceProfileDatabricksCluster"]
}

# ----------------------------
# Output external
# ----------------------------
output "external_aws_iamrole_arn_storage" {
  value = aws_cloudformation_stack.external_storage.outputs["IamRoleArn"]
}
output "external_aws_s3_bucketname_storage" {
  value = aws_cloudformation_stack.external_storage.outputs["S3BucketName"]
}
