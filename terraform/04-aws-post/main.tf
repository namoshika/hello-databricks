terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.75.0"
    }
  }
  backend "local" {
    path = "../tfstates/04-aws-post.tfstate"
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "aws_profile" {
  type    = string
  default = "default"
}
variable "aws_vpcid_external" { type = string }
variable "aws_vpcid_dbxworkspace" { type = string }
variable "aws_sgid_dbxcluster" { type = string }
variable "aws_rtbid_cluster" { type = string }
variable "aws_rtbid_external" { type = string }

# ----------------------------
# Provider
# ----------------------------
provider "aws" {
  profile = var.aws_profile
}

# ----------------------------
# Data
# ----------------------------
data "aws_vpc" "external" {
  id = var.aws_vpcid_external
}
data "aws_vpc" "dbxworkspace" {
  id = var.aws_vpcid_dbxworkspace
}

# ----------------------------
# Workspace Scope - ワークスペースと外部でVPCをピアリング
# ----------------------------
resource "aws_cloudformation_stack" "external_network" {
  name          = "dbx-external-network"
  template_body = file("../../cloudformation/external-network.cf.yaml")
  parameters = {
    VpcIdDatabricksWorkspace         = var.aws_vpcid_dbxworkspace
    VpcIdExternal                    = var.aws_vpcid_external
    CidrDatabricksWorkspace          = data.aws_vpc.dbxworkspace.cidr_block
    CidrExternal                     = data.aws_vpc.external.cidr_block
    RouteTableIdCluster              = var.aws_rtbid_cluster
    RouteTableIdExternal             = var.aws_rtbid_external
    SecurityGroupIdDatabricksCluster = var.aws_sgid_dbxcluster
  }
  tags = { Service = "hello-databricks" }
}

output "aws_securitygroup_id_external" {
  value = aws_cloudformation_stack.external_network.outputs["VpcSecurityGroupIdExternal"]
}
