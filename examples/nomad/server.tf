module "server" {
  source  = "Chhed13/nomad-service/aws"
  version = "0.1.2"

  env_name                      = local.env
  standalone                    = false
  enable_consul                 = true
  instance_type                 = "t3.micro"
  ami_owner                     = "970853308647"
  ami_name                      = "my_prepared_ami_with_consul"
  security_groups_inbound_cidrs = ["10.0.0.0/8"]
  subnet_ids                    = data.terraform_remote_state.base_layer.outputs.subnet_app_ids
  iam_policies                  = ["describe_instances_policy_name"]
  key_name                      = "my_key"
  bootstrap_params              = {
    CONSUL_JOIN        = local.consul_join
    CONSUL_DATACENTER  = local.consul_datacenter
    CONSUL_DOMAIN      = local.consul_domain
    CONSUL_ENCRYPT_KEY = local.conusl_encrypt_key
    CONSUL_AGENT_TOKEN = local.consul_agent_token
    ENV           = local.env
    SERVICE       = local.service
  }
  add_tags                     = local.add_tags
}

resource "null_resource" "set_acl" {
  depends_on = [module.server]
  provisioner "local-exec" {
    environment = {
      NOMAD_ADDR = local.address
    }
    command     = <<-EOF
    sleep 120
    T=$(nomad acl bootstrap)
    echo $T
    TOKEN=$(echo "$T" | grep "Secret ID" | awk '{print $4}')
    aws ssm put-parameter --name ${local.master_acl_ssm} --value $TOKEN --overwrite --type SecureString --profile ${local.profile}
    EOF
  }
}

data "aws_ssm_parameter" "master_token" {
  depends_on      = [null_resource.set_acl]
  name            = local.master_acl_ssm
  with_decryption = true
}

output "master_token" {
  value     = data.aws_ssm_parameter.master_token.value
  sensitive = true
}

resource aws_ssm_parameter nomad_address {
  name  = local.address_ssm
  type  = "String"
  value = local.address
  overwrite = true
  tags  = merge({
    env     = local.env
  }, local.add_tags)
}

output "address" {
  value = local.address
}

output "datacenter" {
  value = local.env
}
