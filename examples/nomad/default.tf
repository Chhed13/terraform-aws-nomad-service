terraform {
  required_version = "~> 0.12.12"
  backend "s3" {
    bucket         = "chhed13-tfstate"
    key            = "nomad/terraform.tfstate"
    dynamodb_table = "chhed13-tfstate"
    region         = "us-east-1"
    profile        = "chhed13"
    encrypt        = true
  }
}

provider "aws" {
  version             = ">= 2.17.0"
  region              = "us-east-1"
  profile             = local.profile
}

data "terraform_remote_state" "base_layer" {
  backend = "s3"
  config  = {
    bucket  = "chhed13-tfstate"
    key     = "base_layer/terraform.tfstate"
    region  = "us-east-1"
    profile = local.profile
  }
}

locals {
  profile            = "chhed13"
  consul_join        = join(",", data.terraform_remote_state.base_layer.outputs.consul_join)
  consul_datacenter  = data.terraform_remote_state.base_layer.outputs.consul_datacenter
  consul_domain      = data.terraform_remote_state.base_layer.outputs.consul_domain
  conusl_encrypt_key = data.terraform_remote_state.base_layer.outputs.consul_encrypt_key
  consul_agent_token = data.terraform_remote_state.base_layer.outputs.consul_agent_token
  nms_endpoint       = data.terraform_remote_state.base_layer.outputs.nms_endpoint
  nms_pass           = data.terraform_remote_state.base_layer.outputs.nms_password
  env                = data.terraform_remote_state.base_layer.outputs.env
  service            = "nomad"
  service_client     = "nomad-client"
  address            = "http://${local.service}.service.${local.consul_datacenter}.${local.consul_domain}:4646"
  address_ssm        = "/nomad/address"
  master_acl_ssm     = "/nomad/acl/masterToken"
  add_tags           = {
    owner       = "chhed13"
    source_repo = "https://github.com/Chhed13/terraform-aws-nomad-service"
    service     = local.service
  }
}