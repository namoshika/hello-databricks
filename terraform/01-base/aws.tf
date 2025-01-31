terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.75.0"
    }
  }
  backend "local" {
    path = "../tfstates/01-base.tfstate"
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
  name          = "dbx-base-basic"
  template_body = file("../../cloudformation/databricks-base-basic.cf.yaml")
  parameters    = { DatabricksAccountId = var.databricks_account_id }
  tags          = { Service = "hello-databricks" }
  capabilities  = ["CAPABILITY_NAMED_IAM"]
}
resource "aws_cloudformation_stack" "databricks_storage" {
  name          = "dbx-workspace-storage"
  template_body = file("../../cloudformation/databricks-storage-workspace.cf.yaml")
  parameters = {
    DatabricksAccountId = var.databricks_account_id,
    S3BucketName        = var.aws_s3_bucketname_workspace
    IsFirstStep         = var.is_firststep ? "True" : "False",
  }
  tags         = { Service = "hello-databricks" }
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
  tags         = { Service = "hello-databricks" }
  capabilities = ["CAPABILITY_NAMED_IAM"]
}

# ----------------------------
# Output databricks
# ----------------------------
output "aws_iamrole_arn_credential" {
  value = aws_cloudformation_stack.databricks_base.outputs["IAMRoleForCredential"]
}
output "aws_iamrole_arn_storage" {
  value = aws_cloudformation_stack.databricks_storage.outputs["IamRoleArn"]
}
output "aws_s3_bucketname_storage" {
  value = aws_cloudformation_stack.databricks_storage.outputs["S3BucketName"]
}
output "external_aws_iam_role_arn_storage" {
  value = aws_cloudformation_stack.external_storage.outputs["IamRoleArn"]
}
output "external_aws_s3_bucketname_storage" {
  value = aws_cloudformation_stack.external_storage.outputs["S3BucketName"]
}
