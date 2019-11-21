# Run Nomad server cluster on AWS 
![Nomad](https://www.nomadproject.io/assets/images/favicons/favicon-194x194-bb8de46a.png)

## Description

Setup Nomad server cluster on AWS EC2 ASG. Allows setup standalone or 3-node server quorum based on
any AMI (Amazon or custom) compatible with Amazon Linux 2.
Inherit bootstrap principals from [cd-on-ec2](https://github.com/Chhed13/terraform-aws-cd-on-ec2) module 
which allows to prepare all tools (Consul, monitoring agent) on AMI baking stage and their bootstrap
script will triggered on start of this module. Just pass the env variables 

## Features

- [x] Support Nomad 0.10.x version
- [x] Support TF 0.12.x version
- [x] Deploy standalone or 3 node cluster
- [x] Make preparation for ACL setup
- [ ] Make initial setup of ACL
- [x] Deployed in ASG and may be rotated accordingly
- [x] Upgrade via server rotation
- [x] auto-restart in case of service failure (but never happens)
- [ ] no manage IAM policies inside module now, provide externally
- [x] tested on Amazon Linux 2, support custom AMIs
- [ ] run from non-root user

## Input variables

| Variable                      |  Type  |  Default                     | Description                                                                                                                          |
|-------------------------------|:------:|:----------------------------:|--------------------------------------------------------------------------------------------------------------------------------------|
| short_name                    |  bool  |           "nom"              | Host middle name. Better not touch it                                                                                                |
| use_acl                       |  bool  |           true               | Setup ACLs or not. Default true                                                                                                      |
| nomad_version                 | string |           0.10.1             | Version of Nomad service to run.                                                                                                     |
| nomad_join                    |  list  |             []               | If set - used in retry_join config. If not - rely on default behaviour (aka Consul join)                                             |
| enable_client                 |  bool  |            false             | For playground purposes only. Enable default client setting, to allow run basic jobs                                                  |
| bootstrap_dir                 | string |             ""               | Path to directory with bootstrap scripts. Default is /opt/bootstrap                                                                  |
| bootstrap_params              |  map   |             {}               | Map of bootstrap parameters needed for bootstrap scripts                                                                             |
| bootstrap_custom_script       | string |             ""               | Allows fine tune start behavour (hot-fix, migrations etc.). Executes after all bootstrap scripts. Not recommended for permanent use. |
| ami_owner                     | string |          "amazon"            | Owner of AMI to use. Account ID or alias                                                                                             |
| ami_name                      | string | "amzn2-ami-hvm-*-x86_64-gp2" | Name of the AMI to run from.                                                                                                         |
| standalone                    |  bool  |            true              | true - up 1 node nomad, false - up 3 node nomad                                                                                      |
| instance_type                 | string |                              | Requiered. Instance type according to AWS notation                                                                                   |
| subnet_ids                    |  list  |                              | Requiered. Subnets where to put instances                                                                                            |
| iam_policies                  |  list  |             []               | Required to access any other AWS resource                                                                                            |
| security_groups_inbound_cidrs |  list  |             []               | list of CIDRs from where to allow traffic (inbound rules). By default same as VPC CDIR                                               |
| key_name                      | string |                              | Requiered. Admin access SSH key name                                                                                                 |
| env_name                      | string |             ""               | Reqiered. Envrironment tag on instance and prefix letter in name                                                                     |
| enable_consul                 |  bool  |            false             | True - apply SG, tags for Consul                                                                                                     |
| add_tags                      |   map  |             {}               | Map of additional tags to provide                                                                                                    |

## Output variables

| Variable             |  Type  | Description              |
|----------------------|:------:|--------------------------|
| encrypt_key          | string | Encrypting key           |
| asg_name             | string | Name of ASG              |
| asg_id               | string | ASG id                   |
| launch_config_id     | string | Launch configuration id  |

## Usage

Watch [example](./examples/run.tf) for parametrization.
No creation IAM policies inside. If you use Consul and rely on AWS Consul auto join provide at least to Describe Tags.

### Setup of ACL

* In this module flag `use_acl` only enable acls in config. Bootstrap them manually according to [docs](https://www.nomadproject.io/guides/security/acl.html)

### Upgrade

__Allways check the update on test cluster first. General config may become incompatible__

* Change nomad_version to new or do any other needed actions. 
* Make `terraform apply`. Nothing breaks here, don't afraid of recreation of Launch Configuration
* Terminate one instance via AWS console or AWS CLI. Instance perform graceful leave procedure upon termination.
* Wait new instance to up and running via ASG policy (usually it takes 1 minute to get up, up to 5 minute to trigger policy) - check in Nomad UI
* Terminate next

### If some instance failing. AWS want your instance down

* Just terminate it