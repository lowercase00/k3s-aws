locals {
  k3s_tls_san_public     = var.create_extlb && var.expose_kubeapi ? aws_lb.external_lb[0].dns_name : ""
  kubeconfig_secret_name = "${var.common_prefix}-kubeconfig-${var.cluster_name}-${var.environment}-v2"
  global_tags = {
    environment      = "${var.environment}"
    provisioner      = "terraform"
    terraform_module = "https://github.com/garutilorenzo/k3s-aws-terraform-cluster"
    k3s_cluster_name = "${var.cluster_name}"
    application      = "k3s"
  }
}

resource "aws_vpc_endpoint" "vpce_secretsmanager" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.AWS_REGION}.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids = var.vpc_subnets
  security_group_ids = [
    aws_security_group.internal_vpce_sg.id,
  ]

  private_dns_enabled = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-secretsmanager-vpce-${var.environment}")
    }
  )
}

## Security

resource "aws_key_pair" "my_ssh_public_key" {
  key_name   = "${var.common_prefix}-ssh-pubkey-${var.environment}"
  public_key = file(var.PATH_TO_PUBLIC_KEY)

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ssh-pubkey-${var.environment}")
    }
  )
}

resource "aws_secretsmanager_secret" "kubeconfig_secret" {
  name        = local.kubeconfig_secret_name
  description = "Kubeconfig k3s. Cluster name: ${var.cluster_name}, environment: ${var.environment}"

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.kubeconfig_secret_name}")
    }
  )
}

resource "random_password" "k3s_token" {
  length  = 55
  special = false
}

## Policies

data "aws_iam_policy" "AmazonEC2ReadOnlyAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

data "aws_iam_policy" "AWSLambdaVPCAccessExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_instances" "k3s_servers" {

  depends_on = [
    aws_autoscaling_group.k3s_servers_asg,
  ]

  instance_tags = {
    k3s-instance-type = "k3s-server"
    provisioner       = "terraform"
    environment       = var.environment
  }

  instance_state_names = ["running"]
}

data "cloudinit_config" "k3s_server" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/files/cloud-config-base.yaml", {})
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/k3s-install-server.sh", {
      k3s_version            = var.k3s_version,
      k3s_token              = random_password.k3s_token.result,
      k3s_subnet             = var.k3s_subnet,
      is_k3s_server          = true,
      efs_csi_driver_release = var.efs_csi_driver_release,
      expose_kubeapi         = var.expose_kubeapi,
      k3s_tls_san_public     = local.k3s_tls_san_public,
      k3s_url                = aws_lb.k3s_server_lb.dns_name,
      k3s_tls_san            = aws_lb.k3s_server_lb.dns_name,
      kubeconfig_secret_name = local.kubeconfig_secret_name
    })
  }
}

## Outputs

output "elb_dns_name" {
  value       = var.create_extlb ? aws_lb.external_lb.*.dns_name : []
  description = "ELB public DNS name"
}

output "k3s_server_public_ips" {
  value = data.aws_instances.k3s_servers.*.public_ips
}
