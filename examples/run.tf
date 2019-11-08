terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region  = "us-east-1"
  profile = "chhed13"
  version = "~> 2.17.0"
}

data "aws_caller_identity" "current" {
}

module "nomad" {
  source                        = "../"
//  ami_name                      = "myservice_amazon_linux_2*" // or full_name_ami_version
//  ami_owner                     = data.aws_caller_identity.current.account_id
  standalone                    = true
  //  bootstrap_dir = ""
  enable_consul                 = false
  //  iam_policies = ""
  instance_type                 = "t3.micro"
  env_name                      = "my"
  key_name                      = "chhed13"
  nomad_datacenter              = "my"
  bootstrap_params              = {
    CONSUL_JOIN            = "\"provider=aws tag_key=consul_env tag_value=my\""
    CONSUL_DATACENTER      = "my_center"
    CONSUL_DOMAIN          = "my.consul"
    ENVIRONMENT            = "my_env"
    MYSERVICE_SPECIAL_INFO = "my_special_info"
  }
  subnet_ids                    = ["subnet-f7f961ab"]
  add_tags                      = {
    version    = "0.1.1"
    consul_env = "my"
  }
  security_groups_inbound_cidrs = ["0.0.0.0/0"] # only for test purposes

}

