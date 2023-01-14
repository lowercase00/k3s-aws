# HTTP
resource "aws_lb" "external_lb" {
  count              = 1
  name               = "${var.common_prefix}-ext-lb-${var.environment}"
  load_balancer_type = "network"
  internal           = "false"
  subnets            = var.vpc_subnets

  enable_cross_zone_load_balancing = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ext-lb-${var.environment}")
    }
  )
}

resource "aws_lb_listener" "external_lb_listener_http" {
  count             = 1
  load_balancer_arn = aws_lb.external_lb[count.index].arn

  protocol = "TCP"
  port     = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external_lb_tg_http[count.index].arn
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-http-listener-${var.environment}")
    }
  )
}

resource "aws_lb_target_group" "external_lb_tg_http" {
  count             = 1
  port              = 80
  protocol          = "TCP"
  vpc_id            = var.vpc_id
  proxy_protocol_v2 = true

  depends_on = [
    aws_lb.external_lb
  ]

  health_check {
    protocol = "TCP"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ext-lb-tg-http-${var.environment}")
    }
  )
}

resource "aws_autoscaling_attachment" "target_http" {
  count = 1
  depends_on = [
    aws_autoscaling_group.k3s_workers_asg,
    aws_lb_target_group.external_lb_tg_http
  ]

  autoscaling_group_name = aws_autoscaling_group.k3s_workers_asg.name
  lb_target_group_arn    = aws_lb_target_group.external_lb_tg_http[count.index].arn
}

# HTTPS

resource "aws_lb_listener" "external_lb_listener_https" {
  count             = 1
  load_balancer_arn = aws_lb.external_lb[count.index].arn

  protocol = "TCP"
  port     = var.443

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external_lb_tg_https[count.index].arn
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-https-listener-${var.environment}")
    }
  )
}

resource "aws_lb_target_group" "external_lb_tg_https" {
  count             = 1
  port              = var.443
  protocol          = "TCP"
  vpc_id            = var.vpc_id
  proxy_protocol_v2 = true

  depends_on = [
    aws_lb.external_lb
  ]

  health_check {
    protocol = "TCP"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ext-lb-tg-https-${var.environment}")
    }
  )
}

resource "aws_autoscaling_attachment" "target_https" {
  count = 1
  depends_on = [
    aws_autoscaling_group.k3s_workers_asg,
    aws_lb_target_group.external_lb_tg_https
  ]

  autoscaling_group_name = aws_autoscaling_group.k3s_workers_asg.name
  lb_target_group_arn    = aws_lb_target_group.external_lb_tg_https[count.index].arn
}

# kubeapi

resource "aws_lb_listener" "external_lb_listener_kubeapi" {
  count             = var.expose_kubeapi ? 1 : 0
  load_balancer_arn = aws_lb.external_lb[count.index].arn

  protocol = "TCP"
  port     = var.kube_api_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external_lb_tg_kubeapi[count.index].arn
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-kubeapi-listener-${var.environment}")
    }
  )
}

resource "aws_lb_target_group" "external_lb_tg_kubeapi" {
  count    = var.expose_kubeapi ? 1 : 0
  port     = var.kube_api_port
  protocol = "TCP"
  vpc_id   = var.vpc_id

  depends_on = [
    aws_lb.external_lb
  ]

  health_check {
    protocol = "TCP"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ext-lb-tg-kubeapi-${var.environment}")
    }
  )
}

resource "aws_autoscaling_attachment" "target_kubeapi" {
  count = var.expose_kubeapi ? 1 : 0
  depends_on = [
    aws_autoscaling_group.k3s_servers_asg,
    aws_lb_target_group.external_lb_tg_kubeapi
  ]

  autoscaling_group_name = aws_autoscaling_group.k3s_servers_asg.name
  lb_target_group_arn    = aws_lb_target_group.external_lb_tg_kubeapi[count.index].arn
}

# Internal

resource "aws_lb" "k3s_server_lb" {
  name               = "${var.common_prefix}-int-lb-${var.environment}"
  load_balancer_type = "network"
  internal           = "true"
  subnets            = var.vpc_subnets

  enable_cross_zone_load_balancing = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-int-lb-${var.environment}")
    }
  )
}

resource "aws_lb_listener" "k3s_server_listener" {
  load_balancer_arn = aws_lb.k3s_server_lb.arn

  protocol = "TCP"
  port     = var.kube_api_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_server_tg.arn
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-kubeapi-listener-${var.environment}")
    }
  )
}

resource "aws_lb_target_group" "k3s_server_tg" {
  port     = var.kube_api_port
  protocol = "TCP"
  vpc_id   = var.vpc_id


  depends_on = [
    aws_lb.k3s_server_lb
  ]

  health_check {
    protocol = "TCP"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-internal-lb-tg-kubeapi-${var.environment}")
    }
  )
}

resource "aws_autoscaling_attachment" "k3s_server_target_kubeapi" {

  depends_on = [
    aws_autoscaling_group.k3s_servers_asg,
    aws_lb_target_group.k3s_server_tg
  ]

  autoscaling_group_name = aws_autoscaling_group.k3s_servers_asg.name
  lb_target_group_arn    = aws_lb_target_group.k3s_server_tg.arn
}
