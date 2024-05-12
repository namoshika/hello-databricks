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
# AWS
# ----------------------------
resource "aws_cloudformation_stack" "base" {
  name          = "databricks-base-basic"
  template_body = file("../../cloudformation/databricks-base-basic.cf.yaml")
  parameters    = { DatabricksAccountId = var.databricks_account_id }
  tags          = { Service = "hello-databricks" }
  capabilities  = ["CAPABILITY_NAMED_IAM"]
}
resource "aws_cloudformation_stack" "storage_workspace" {
  name          = "databricks-storage-workspace"
  template_body = file("../../cloudformation/databricks-storage-workspace.cf.yaml")
  parameters = {
    DatabricksAccountId = var.databricks_account_id,
    S3BucketName        = var.aws_s3_bucketname_workspace
    IsFirstStep         = var.is_firststep ? "True" : "False",
  }
  tags         = { Service = "hello-databricks" }
  capabilities = ["CAPABILITY_NAMED_IAM"]
}
resource "aws_cloudformation_stack" "storage_input" {
  name          = "databricks-storage-input"
  template_body = file("../../cloudformation/databricks-storage-external.cf.yaml")
  parameters = {
    DatabricksAccountId = var.databricks_account_id,
    S3BucketName        = var.aws_s3_bucketname_input
    IsFirstStep         = var.is_firststep ? "True" : "False",
  }
  tags         = { Service = "hello-databricks" }
  capabilities = ["CAPABILITY_NAMED_IAM"]
}


# ----------------------------
# Output
# ----------------------------
output "aws_iam_role_arn_credential" {
  value = aws_cloudformation_stack.base.outputs["IAMRoleForCredential"]
}
output "aws_iam_role_arn_workspace" {
  value = aws_cloudformation_stack.storage_workspace.outputs["IamRoleArn"]
}
output "aws_s3_bucketname_workspace" {
  value = aws_cloudformation_stack.storage_workspace.outputs["S3BucketName"]
}
output "aws_iam_role_arn_input" {
  value = aws_cloudformation_stack.storage_input.outputs["IamRoleArn"]
}
output "aws_s3_bucketname_input" {
  value = aws_cloudformation_stack.storage_input.outputs["S3BucketName"]
}
