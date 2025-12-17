terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.75.0"
    }
  }
  backend "local" {
    path = "../tfstates/01-aws-network-cmvpc.tfstate"
  }
}

# ----------------------------
# Variable
# ----------------------------
variable "aws_profile" {
  type    = string
  default = "default"
}
variable "aws_az_a_dbx" {
  type    = string
  default = "ap-northeast-1a"
}
variable "aws_az_b_dbx" {
  type    = string
  default = "ap-northeast-1c"
}
variable "aws_vpcid_external" {
  type = string
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
resource "aws_cloudformation_stack" "databricks_network" {
  name          = "dbx-workspace-network"
  template_body = file("../../cloudformation/databricks-workspace-network.cf.yaml")
  parameters = {
    VpcSubnetAzASide = var.aws_az_a_dbx
    VpcSubnetAzBSide = var.aws_az_b_dbx
  }
  tags         = { Service = "hello-databricks" }
  capabilities = ["CAPABILITY_NAMED_IAM"]
}

# ----------------------------
# Output databricks
# ----------------------------
output "aws_vpc_id" {
  value = aws_cloudformation_stack.databricks_network.outputs["VpcId"]
}
output "aws_vpc_name" {
  value = aws_cloudformation_stack.databricks_network.outputs["VpcName"]
}
output "aws_subnet_id_cluster_a" {
  value = aws_cloudformation_stack.databricks_network.outputs["SubnetIdClusterA"]
}
output "aws_subnet_id_cluster_b" {
  value = aws_cloudformation_stack.databricks_network.outputs["SubnetIdClusterB"]
}
output "aws_securitygroup_id_cluster" {
  value = aws_cloudformation_stack.databricks_network.outputs["SecurityGroupIdCluster"]
}
output "aws_endpoint_id_scc" {
  value = aws_cloudformation_stack.databricks_network.outputs["VPCEndpointIdScc"]
}
output "aws_endpoint_name_scc" {
  value = aws_cloudformation_stack.databricks_network.outputs["VPCEndpointNameScc"]
}
output "aws_endpoint_id_internal" {
  value = aws_cloudformation_stack.databricks_network.outputs["VPCEndpointIdInternal"]
}
output "aws_endpoint_name_internal" {
  value = aws_cloudformation_stack.databricks_network.outputs["VPCEndpointNameInternal"]
}
