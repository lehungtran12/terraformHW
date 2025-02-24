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

###############################################################################################################

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
###############################################################################################################

# resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic_from_ssh" {
#   security_group_id = aws_security_group.allow_basic.id
#   from_port         = 22
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "tcp"
#   to_port           = 22
# }

resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic_from_http" {
  security_group_id = aws_security_group.allow_basic.id
  referenced_security_group_id  = aws_security_group.allow_basic.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_basic.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_basic.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
###############################################################################################################

resource "aws_security_group" "allow_basic" {
  name        = "allow_basic"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "allow_basic"
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "hungssh"
  public_key = var.ssh_public_key
}
###############################################################################################################

# resource "aws_instance" "ubuntu" {
#   ami                    = data.aws_ami.ubuntu.id
#   instance_type          = var.instance_type
#   vpc_security_group_ids = [aws_security_group.allow_basic.id]
#   key_name               = aws_key_pair.ssh_key.key_name

#   tags = {
#     Name    = var.instance_name
#     Project = "devops"
#     Creator = "Hung"
#   }
#   user_data = file("userdata.sh")
# }
# resource "aws_vpc" "HungVPC" {
#   cidr_block = "10.0.0.0/16"
# }
# resource "aws_subnet" "private_subnet" {
#   vpc_id                  = aws_vpc.HungVPC.id
#   cidr_block              = "10.0.2.0/24"
#   map_public_ip_on_launch = true
#   availability_zone       = ["us-west-2a", "us-west-2b", "us-west-2c"]
# }


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

resource "aws_launch_template" "ubuntu" {
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  #vpc_security_group_ids = [aws_security_group.allow_basic.id]
  key_name = aws_key_pair.ssh_key.key_name

  tags = {
    Name    = var.instance_name
    Project = "devops"
    Creator = "Hung"
  }
  user_data = base64encode(file("userdata.sh"))

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow_basic.id]
  }

}

resource "aws_autoscaling_group" "bar" {
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2
  vpc_zone_identifier = module.vpc.private_subnets

  launch_template {
    id      = aws_launch_template.ubuntu.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.hung.arn]
}


resource "aws_lb_target_group" "hung" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb" "hung" {
  name               = "hung-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_basic.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  access_logs {
    bucket  = "hungbucket123456"
    prefix  = "test-lb"
    enabled = false
  }

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "hung" {
  load_balancer_arn = aws_lb.hung.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hung.arn
  }
}