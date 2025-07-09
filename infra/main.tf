# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = data.aws_availability_zones.available.names
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# EKS Cluster using public module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.35.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                         = data.aws_vpc.default.id
  subnet_ids                     = data.aws_subnets.default.ids
  cluster_endpoint_public_access = true

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
    disk_size = 20
  }

  eks_managed_node_groups = {
    main = {
      name = "${var.cluster_name}-main"

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Launch template configuration
      create_launch_template = false
      launch_template_name   = ""

      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }

      tags = {
        Environment = var.environment
        Terraform   = "true"
      }
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}
