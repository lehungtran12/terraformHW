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


resource "aws_key_pair" "ssh_key" {
  key_name   = "hungssh"
  public_key = var.ssh_public_key
}


resource "aws_security_group" "allow_basic" {
  name        = "allow_basic"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "allow_basic"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic_from_alb_sg" {
  security_group_id            = aws_security_group.allow_basic.id
  referenced_security_group_id = var.alb_sg
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_basic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_allow_basic" {
  security_group_id = aws_security_group.allow_basic.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6_allow_basic" {
  security_group_id = aws_security_group.allow_basic.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports 
}

resource "aws_launch_template" "ubuntu" {
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.ssh_key.key_name

  tags = {
    Name    = var.instance_name
    Project = "devops"
    Creator = "Hung"
  }
  user_data = base64encode(file("modules/Instances/userdata.sh"))

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.allow_basic.id]
  }

}

resource "aws_autoscaling_group" "bar" {
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2
  vpc_zone_identifier = var.vpc_public_subnet

  launch_template {
    id      = aws_launch_template.ubuntu.id
    version = "$Latest"
  }
  target_group_arns = [var.tg_arn]
}

