locals {
  full_name             = "Nomad"
  name                  = "${format("%0.1s%s", lower(var.env_name), var.short_name)}l"
  count         = var.standalone ? 1 : 3
  default_bootstrap_dir = "/opt/bootstrap"
  cidr                  = length(var.security_groups_inbound_cidrs) == 0 ? [data.aws_vpc.vpc.cidr_block] : var.security_groups_inbound_cidrs
  params          = join(" ", formatlist("%s='%s'", keys(var.bootstrap_params), values(var.bootstrap_params)))

  tags = merge({
    Name = local.name,
    env  = var.env_name
  }, var.add_tags)

  nomad_config = <<-EOF
  log_json = true
  bind_addr = "0.0.0.0"
  datacenter = "${var.env_name}"
  leave_on_interrupt = true
  leave_on_terminate = true
  server {
    enabled = true
    bootstrap_expect = ${local.count}
    encrypt = "${random_id.encrypt_key.b64_std}"
  }
  %{ if var.use_acl }
  acl {
    enabled = true
  }
  %{ endif }
  %{ if var.enable_client }
  client {
    enabled = true
    options = {
      "driver.raw_exec.enable" = "1"
    }
  }
  plugin "raw_exec" {
    config {
      enabled = true
    }
  }
  %{ endif }
  EOF

  nomad_install = <<-EOF
  #!/bin/bash

  NAME=nomad
  VERSION=${var.nomad_version}

  cd /tmp
  curl -O https://releases.hashicorp.com/$NAME/$VERSION/$NAME\_$VERSION\_linux_amd64.zip
  unzip $NAME\_$VERSION\_linux_amd64.zip
  chmod +x $NAME
  mv $NAME /usr/bin/$NAME

  cat << BOF > /tmp/$NAME.service
  [Unit]
  Description=Nomad
  After=network.target
  Wants=network.target
  Documentation=https://nomadproject.io/docs/

  [Service]
  ExecStart=/usr/bin/nomad agent -config=/etc/nomad.d -data-dir=/var/lib/nomad
  ExecReload=/bin/kill -HUP $MAINPID
  WorkingDirectory=/var/lib/nomad
  KillMode=process
  KillSignal=SIGINT
  LimitNOFILE=infinity
  LimitNPROC=infinity
  Restart=on-failure
  RestartSec=2
  StartLimitBurst=3
  StartLimitIntervalSec=10
  TasksMax=infinity

  [Install]
  WantedBy=multi-user.target
  BOF

  chown root:root /tmp/$NAME.service
  mv /tmp/$NAME.service /etc/systemd/system/

  mkdir -p /etc/$NAME.d
  mkdir -p /var/lib/$NAME

  systemctl daemon-reload
  systemctl enable $NAME
  EOF
}

data "aws_ami" "image" {
  most_recent = true
  owners      = [var.ami_owner]
  filter {
    name   = "name"
    values = [var.ami_name]
  }
}

data aws_subnet sn {
  id = var.subnet_ids[0]
}

data "aws_vpc" "vpc" {
  id = data.aws_subnet.sn.vpc_id
}

resource "random_id" "encrypt_key" {
  byte_length = 16
  lifecycle {
    ignore_changes = all
  }
}

data "template_file" "userdata" {
  template = file("${path.module}/userdata.tpl")
  vars     = {
    hostname      = local.name
    params        = local.params
    bootstrap_dir = var.bootstrap_dir == "" ? local.default_bootstrap_dir : var.bootstrap_dir
    custom_script = base64encode(var.bootstrap_custom_script)
    nomad_install = base64encode(local.nomad_install)
    nomad_config  = base64encode(local.nomad_config)
  }
}

resource "local_file" "f" {
  content = data.template_file.userdata.rendered
  filename = "udata.yml"
}