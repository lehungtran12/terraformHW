terraform {
  backend "s3" {
    bucket = "hungbucket123456"
    key    = "terraform/tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.79.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "Hung-vpc"
  cidr = "10.0.0.0/16"

  azs             = var.aws_availability_zones
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "alb_sg" {
  source             = "./modules/Load_Balancer"
  vpc_id             = module.vpc.vpc_id
  vpc_private_subnet = module.vpc.private_subnets
  vpc_public_subnet  = module.vpc.public_subnets
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  depends_on = [module.vpc]

  cluster_name    = var.cluster_name
  cluster_version = "1.31"


  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t2.small"]
    capacity_type  = "SPOT"
  }

  eks_managed_node_groups = {
    node_group_one = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type = "AL2023_x86_64_STANDARD"

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# module "instance" {
#   vpc_private_subnet = module.vpc.private_subnets
#   vpc_public_subnet  = module.vpc.public_subnets
#   vpc_id             = module.vpc.vpc_id
#   source             = "./modules/Instances"
#   depends_on         = [module.alb_sg]
#   instance_name      = var.instance_name
#   instance_type      = var.instance_type
#   alb_sg             = module.alb_sg.lb_sg
#   tg_arn             = module.alb_sg.target_group_arn
# }