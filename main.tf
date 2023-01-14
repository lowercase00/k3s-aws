variable "AWS_ACCESS_KEY" {

}

variable "AWS_SECRET_KEY" {

}

variable "AWS_REGION" {
  type        = string
  default     = "us-east-1"
  description = "AWS Zone"
}

module "k3s_cluster" {
  AWS_REGION        = "us-east-1"
  environment       = "staging"
  my_public_ip_cidr = "<change_me>"
  vpc_id            = "<change_me>"
  vpc_subnets       = ["<change_me>", "<change_me>", "<change_me>"]
  vpc_subnet_cidr   = "<change_me>"
  cluster_name      = "k3s-cluster"
  create_extlb      = true # or flase
  expose_kubeapi    = true # or flase
  source            = "./k3s_cluster/"
}

output "elb_dns_name" {
  value = module.k3s_cluster.elb_dns_name
}

output "k3s_server_public_ips" {
  value = module.k3s_cluster.k3s_server_public_ips
}

output "k3s_workers_public_ips" {
  value = module.k3s_cluster.k3s_workers_public_ips
}
