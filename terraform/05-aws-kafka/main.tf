terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.75.0"
    }
  }
  backend "local" {
    path = "../tfstates/05-aws-kafka.tfstate"
  }
}

variable "aws_profile" {
  type    = string
  default = "default"
}
variable "aws_keypair" { type = string }
variable "aws_subnet_id_bastion" { type = string }
variable "aws_subnet_id_broker_a" { type = string }
variable "aws_subnet_id_broker_b" { type = string }
variable "aws_securitygroup_id_public" { type = string }

# ----------------------------
# Provider
# ----------------------------
provider "aws" {
  profile = var.aws_profile
}

# ----------------------------
# Data
# ----------------------------
data "terraform_remote_state" "aws_post" {
  backend = "local"
  config  = { path = "../tfstates/04-aws-post.tfstate" }
}
locals {
  aws_securitygroup_id_external = data.terraform_remote_state.aws_post.outputs.aws_securitygroup_id_external
}

# ----------------------------
# Kafka Cluster
# ----------------------------
resource "aws_cloudformation_stack" "external_kafka" {
  name          = "dbx-external-kafka"
  template_body = file("../../cloudformation/external-kafka-provisioned.cf.yaml")
  parameters = {
    Broker1Subnet         = var.aws_subnet_id_broker_a
    Broker2Subnet         = var.aws_subnet_id_broker_b
    BastionSubnet         = var.aws_subnet_id_bastion
    BastionKeyPair        = var.aws_keypair
    SecurityGroupPublic   = var.aws_securitygroup_id_public
    SecurityGroupInternal = local.aws_securitygroup_id_external
  }
  tags         = { Service = "hello-databricks" }
  capabilities = ["CAPABILITY_NAMED_IAM"]
  timeouts {
    create = "60m"
    update = "60m"
  }
}
