terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.58.0"
    }
  }
  backend "local" {
    path = "../tfstates/04-external-kafka.tfstate"
  }
}

variable "aws_keypair" { type = string }

# ----------------------------
# Data
# ----------------------------
data "terraform_remote_state" "aws_network" {
  backend = "local"
  config  = { path = "../tfstates/01-aws-network.tfstate" }
}
locals {
  aws_subnet_id_public          = data.terraform_remote_state.aws_network.outputs.aws_subnet_id_public
  aws_subnet_id_cluster_a       = data.terraform_remote_state.aws_network.outputs.aws_subnet_id_cluster_a
  aws_subnet_id_cluster_b       = data.terraform_remote_state.aws_network.outputs.aws_subnet_id_cluster_b
  aws_securitygroup_id_public   = data.terraform_remote_state.aws_network.outputs.aws_securitygroup_id_public
  aws_securitygroup_id_endpoint = data.terraform_remote_state.aws_network.outputs.aws_securitygroup_id_endpoint
}

# ----------------------------
# Kafka Cluster
# ----------------------------
resource "aws_cloudformation_stack" "external_kafka" {
  name          = "dbx-external-kafka"
  template_body = file("../../cloudformation/external-kafka-provisioned.cf.yaml")
  parameters = {
    Broker1Subnet         = local.aws_subnet_id_cluster_a
    Broker2Subnet         = local.aws_subnet_id_cluster_b
    BastionSubnet         = local.aws_subnet_id_public
    BastionKeyPair        = var.aws_keypair
    SecurityGroupInternal = local.aws_securitygroup_id_endpoint
    SecurityGroupPublic   = local.aws_securitygroup_id_public
  }
  tags         = { Service = "hello-databricks" }
  capabilities = ["CAPABILITY_NAMED_IAM"]
  timeouts {
    create = "60m"
    update = "60m"
  }
}
