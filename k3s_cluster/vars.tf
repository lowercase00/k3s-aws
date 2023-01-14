variable "AWS_REGION" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "common_prefix" {
  type    = string
  default = "k3s"
}

variable "k3s_version" {
  type    = string
  default = "latest"
}

variable "k3s_subnet" {
  type    = string
  default = "default_route_table"
}

## eu-west-1
# Ubuntu 22.04
# ami-099b1e41f3043ce3a

# Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
# ami-0ea0f26a6d50850c5

variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-0f01974d5fd3b4530"
  }
}

variable "PATH_TO_PUBLIC_KEY" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = "Path to your public key"
}

variable "PATH_TO_PRIVATE_KEY" {
  type        = string
  default     = "~/.ssh/id_rsa"
  description = "Path to your private key"
}

variable "vpc_id" {
  type        = string
  description = "The vpc id"
}

variable "my_public_ip_cidr" {
  type        = string
  description = "My public ip CIDR"
}

variable "efs_csi_driver_release" {
  type    = string
  default = "v1.4.2"
}

variable "vpc_subnet_cidr" {
  type        = string
  description = "VPC subnet CIDR"
}

variable "vpc_subnets" {
  type        = list(any)
  description = "The vpc subnets ids"
}

variable "default_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "Instance type to be used"
}

variable "instance_types" {
  description = "List of instance types to use"
  type        = map(string)
  default = {
    asg_instance_type_1 = "t3.medium"
    asg_instance_type_2 = "t3a.medium"
    asg_instance_type_3 = "c5a.large"
    asg_instance_type_4 = "c6a.large"
  }
}

variable "kube_api_port" {
  type        = number
  default     = 6443
  description = "Kubeapi Port"
}

variable "create_extlb" {
  type        = bool
  default     = false
  description = "Create external LB true/false"
}



variable "k3s_server_desired_capacity" {
  type        = number
  default     = 3
  description = "K3s server ASG desired capacity"
}

variable "k3s_server_min_capacity" {
  type        = number
  default     = 3
  description = "K3s server ASG min capacity"
}

variable "k3s_server_max_capacity" {
  type        = number
  default     = 4
  description = "K3s server ASG max capacity"
}

variable "cluster_name" {
  type        = string
  default     = "k3s-cluster"
  description = "Cluster name"
}

variable "expose_kubeapi" {
  type    = bool
  default = true
}
