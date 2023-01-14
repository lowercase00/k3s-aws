resource "aws_autoscaling_group" "k3s_servers_asg" {
  name                      = "${var.common_prefix}-servers-asg-${var.environment}"
  wait_for_capacity_timeout = "5m"
  vpc_zone_identifier       = var.vpc_subnets

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }

  desired_capacity          = var.k3s_server_desired_capacity
  min_size                  = var.k3s_server_min_capacity
  max_size                  = var.k3s_server_max_capacity
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true

  dynamic "tag" {
    for_each = local.global_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.common_prefix}-server-${var.environment}"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "k3s_server" {
  name_prefix   = "${var.common_prefix}-k3s-server-tpl-${var.environment}"
  image_id      = var.AMIS[var.AWS_REGION]
  instance_type = var.default_instance_type
  user_data     = data.cloudinit_config.k3s_server.rendered

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 30
      encrypted   = true
    }
  }

  key_name = aws_key_pair.my_ssh_public_key.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow_strict.id]
  }

  private_dns_name_options {
    hostname_type = "resource-name"
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-k3s-server-tpl-${var.environment}")
    }
  )

}
