module "client_windows" {
  source  = "Chhed13/cd-on-ec2/aws"
  version = "0.1.3"

  env_name                      = local.env
  enable_consul                 = true
  for_windows                   = true
  ami_owner                     = "my_acc"
  instance_type                 = "t3.micro"
  ami_name                      = "my_base_win2016_ami_with_consul"
  security_groups_inbound_cidrs = ["10.0.0.0/8"]
  asg_min_size                  = 1
  asg_desired_size              = 1
  asg_max_size                  = 1

  subnet_ids     = data.terraform_remote_state.base_layer.outputs.subnets
  iam_policies   = ["describe_instances_policy_name", "other_policies_req_by_apps"]
  key_name       = "my_key"
  health_timeout = 300

  full_name        = local.service_client
  short_name       = "nomc"
  service_port     = 4647
  bootstrap_params = {
    CONSUL_JOIN        = local.consul_join
    CONSUL_DATACENTER  = local.consul_datacenter
    CONSUL_DOMAIN      = local.consul_domain
    CONSUL_ENCRYPT_KEY = local.conusl_encrypt_key
    CONSUL_AGENT_TOKEN = local.consul_agent_token
    ENV                = local.env
    SERVICE            = local.service_client
    NOMAD_DATACENTER   = local.env
  }
  add_tags         = local.add_tags
}

module "client_linux" {
  source  = "Chhed13/cd-on-ec2/aws"
  version = "0.1.3"

  env_name                      = local.env
  enable_consul                 = true
  for_windows                   = false
  ami_owner                     = "my_acc"
  instance_type                 = "t3.micro"
  ami_name                      = "my_base_ami_linux2_with_consul"
  security_groups_inbound_cidrs = ["10.0.0.0/8"]

  subnet_ids     = data.terraform_remote_state.base_layer.outputs.subnets
  iam_policies   = ["describe_instances_policy_name", "other_policies_req_by_apps"]
  key_name       = "my_key"
  health_timeout = 300

  full_name        = local.service_client
  short_name       = "nomc"
  service_port     = 4647
  bootstrap_params = {
    CONSUL_JOIN        = local.consul_join
    CONSUL_DATACENTER  = local.consul_datacenter
    CONSUL_DOMAIN      = local.consul_domain
    CONSUL_ENCRYPT_KEY = local.conusl_encrypt_key
    CONSUL_AGENT_TOKEN = local.consul_agent_token
    ENV                = local.env
    SERVICE            = local.service_client
    NOMAD_DATACENTER   = local.env
  }
  add_tags         = local.add_tags
}