variable "short_name" {
  type        = string
  default     = "nom"
  description = "Required. Short name of service. Only lower case, 2-4 letters. Ex: msr"
}

variable "use_acl" {
  default     = true
  description = "Enable ACLs or not. Default true"
}

variable "nomad_version" {
  type        = string
  default     = "0.10.1"
  description = "Version of Nomad service to run."
}

variable "nomad_join" {
  type        = list(string)
  default     = []
  description = "If set - used in retry_join config. If not - relay on default behavour (aka Consul join)"
}

variable "enable_client" {
  type        = bool
  default     = false
  description = "For playground purposes only. Enable defaul client setting, to allow run basic jobs"
}

variable bootstrap_dir {
  type        = string
  default     = ""
  description = "Path to directory with bootstrap scripts. Default is /opt/bootstrap"
}

variable "bootstrap_params" {
  type        = map(string)
  default     = {}
  description = "Map of bootstrap parameters needed for bootstrap scripts"
}

variable "bootstrap_custom_script" {
  type        = string
  default     = ""
  description = "Allows fine tune start behavour (hot-fix, migrations etc.). Executes after all bootstrap scripts. Not recommended for permanent use."
}

// AWS Auto-scaling, placement and policy params /////////////////
variable "ami_owner" {
  type        = string
  default     = "amazon"
  description = "Owner of AMI to use. Account ID or alias"
}

variable "ami_name" {
  type        = string
  default     = "amzn2-ami-hvm-*-x86_64-gp2"
  description = "Name of the AMI to run from. Good practice to have smth like {company_prefix}_{lower(var.full_name)}_{var.ami_version}"
}

variable "standalone" {
  default     = true
  description = "true - up 1 node nomad, false - up 3 node nomad"
}

variable "instance_type" {
  type        = string
  description = "Requiered. Instance type according to AWS notation"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Requiered. Subnets where to put instances"
}

variable "iam_policies" {
  default     = []
  type        = list(string)
  description = "Required to access any other AWS resource"
}

variable "security_groups_inbound_cidrs" {
  default     = []
  type        = list(string)
  description = "list of CIDRs from where to allow traffic (inbound rules). By default same as VPC CDIR"
}

variable "key_name" {
  type        = string
  description = "Requiered. Admin access SSH key name"
}

// Environment and infra params //////////
variable "env_name" {
  type        = string
  description = "Reqiered. Envrironment tag on instance and prefix letter in name"
}

variable "enable_consul" {
  default     = false
  description = "True - apply SG, tags for Consul"
}

variable "add_tags" {
  type        = map(string)
  default     = {}
  description = "Map of additional tags to provide"
}