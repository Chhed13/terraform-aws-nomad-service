terraform {
  required_version = "~> 0.12.12"
  backend "s3" {
    bucket         = "chhed13-tfstate"
    key            = "nomad_acl/terraform.tfstate"
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

data "terraform_remote_state" "nomad" {
  backend = "s3"
  config  = {
    bucket  = "chhed13-tfstate"
    key     = "nomad/terraform.tfstate"
    region  = "us-east-1"
    profile = local.profile
  }
}

provider "nomad" {
  address   = data.terraform_remote_state.nomad.outputs.address
  secret_id = data.terraform_remote_state.nomad.outputs.master_token
}

locals {
  env            = data.terraform_remote_state.base_layer.outputs.env
  service        = "nomad"
  admin_acl_ssm = "/nomad/acl/adminToken"
  profile        = "chhed13"
  add_tags       = {
    owner       = "chhed13"
    source_repo = "https://github.com/Chhed13/terraform-aws-nomad-service"
  }
}

resource "nomad_acl_policy" "anonymous" {
  name        = "anonymous"
  description = "Default policy"
  rules_hcl   = <<-EOF
  namespace "default" {
    policy = "read"
  }

  agent {
    policy = "read"
  }

  node {
    policy = "read"
  }
  EOF
}

resource "nomad_acl_policy" "admin" {
  name        = "admin"
  description = "Policy for administrating jobs"
  rules_hcl   = <<-EOF
  namespace "default" {
    policy = "write"
  }

  agent {
    policy = "write"
  }

  node {
    policy = "write"
  }

  operator {
    policy = "write"
  }

  quota {
    policy = "write"
  }

  host_volume {
    policy = "write"
  }
  EOF
}

resource "nomad_acl_token" "admin" {
  type     = "client"
  name     = "admin"
  policies = [nomad_acl_policy.admin.name]
}

resource "aws_ssm_parameter" "admin_token" {
  name      = local.admin_acl_ssm
  type      = "SecureString"
  value     = nomad_acl_token.admin.secret_id
  overwrite = true
  tags      = merge({
    service = local.service,
    env     = local.env
  }, local.add_tags)
}

output "admin_token" {
  value     = aws_ssm_parameter.admin_token.value
  sensitive = true
}