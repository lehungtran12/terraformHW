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

module "instance" {
  vpc_private_subnet = module.vpc.private_subnets
  vpc_public_subnet  = module.vpc.public_subnets
  vpc_id             = module.vpc.vpc_id
  source             = "./modules/Instances"
  depends_on         = [module.alb_sg]
  instance_name      = var.instance_name
  instance_type      = var.instance_type
  alb_sg             = module.alb_sg.lb_sg
  tg_arn             = module.alb_sg.target_group_arn
}