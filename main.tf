resource "aws_iam_role" "role" {
  name               = "IamRole-${local.name}"
  description        = "Role for the ${local.full_name} in ${var.env_name} environment"
  assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":[\"s3.amazonaws.com\",\"ec2.amazonaws.com\"]},\"Action\":\"sts:AssumeRole\"}]}"
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  count      = length(var.iam_policies)
  role       = aws_iam_role.role.name
  policy_arn = element(var.iam_policies, count.index)
}

resource "aws_iam_instance_profile" "profile" {
  depends_on = [aws_iam_role_policy_attachment.attach]
  name       = aws_iam_role.role.name
  role       = aws_iam_role.role.name
}

resource "aws_launch_configuration" "lc" {
  name_prefix          = "${local.name}-"
  image_id             = data.aws_ami.image.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  security_groups      = [aws_security_group.sg.id]
  user_data_base64     = base64encode(data.template_file.userdata.rendered)
  iam_instance_profile = aws_iam_instance_profile.profile.name
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name_prefix               = "${local.name}-"
  vpc_zone_identifier       = var.subnet_ids
  max_size                  = local.count
  min_size                  = local.count
  desired_capacity          = local.count
  health_check_grace_period = 300
  health_check_type         = "EC2"
  default_cooldown          = 300
  launch_configuration      = aws_launch_configuration.lc.name
  wait_for_capacity_timeout = "5m"
  termination_policies      = ["OldestInstance", "OldestLaunchConfiguration"]
  protect_from_scale_in     = true
  force_delete              = true

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

//////////////// SECURITY GROUPS ////////////////////////
resource "aws_security_group" "sg" {
  name_prefix = "${local.name}-sg-"
  description = "Security group to associate with ${local.full_name} servers in ${var.env_name} environment"
  vpc_id      = data.aws_subnet.sn.vpc_id
  tags        = local.tags
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "allow_icmp" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = local.cidr
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "allow_remote" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.cidr
  security_group_id = aws_security_group.sg.id
}

// followed the doc https://www.nomadproject.io/guides/install/production/requirements.html#ports-used
resource "aws_security_group_rule" "allow_nomad_rpc" {
  type              = "ingress"
  from_port         = 4647
  to_port           = 4647
  protocol          = "tcp"
  cidr_blocks       = local.cidr
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "allow_nomad_http" {
  type              = "ingress"
  from_port         = 4646
  to_port           = 4646
  protocol          = "tcp"
  cidr_blocks       = local.cidr
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "allow_nomad_wan_tcp" {
  type              = "ingress"
  from_port         = 4648
  to_port           = 4648
  protocol          = "tcp"
  cidr_blocks       = local.cidr
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "allow_nomad_wan_udp" {
  type              = "ingress"
  from_port         = 4648
  to_port           = 4648
  protocol          = "udp"
  cidr_blocks       = local.cidr
  security_group_id = aws_security_group.sg.id
}

// followed the doc: https://www.consul.io/docs/agent/options.html#ports-used
resource "aws_security_group_rule" "allow_consul_serf_tcp" {
  count             = var.enable_consul ? 1 : 0
  type              = "ingress"
  from_port         = 8301
  to_port           = 8302
  protocol          = "tcp"
  cidr_blocks       = local.cidr
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "allow_consul_serf_udp" {
  count             = var.enable_consul ? 1 : 0
  type              = "ingress"
  from_port         = 8301
  to_port           = 8302
  protocol          = "udp"
  cidr_blocks       = local.cidr
  security_group_id = aws_security_group.sg.id
}

