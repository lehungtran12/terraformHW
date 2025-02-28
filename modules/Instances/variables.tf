variable "instance_name" {
  description = "EC2 instance"
  type        = string
  default     = "EC-2"
}

variable "instance_type" {
  description = "instance type"
  type        = string
  default     = "t2.micro"
}

variable "aws_region" {
  description = "Region"
  type        = string
  default     = "us-east-1"
}

variable "alb_sg" {
  description = "sg for the EC2 instance"
  type        = string
}

variable "aws_availability_zones" {
  description = "Region"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "ssh_public_key" {
  type    = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIKZCaJgoHNkFAvNzU+YL0ueT8iYIJNYXAkhumfgCGf3 hung_ssh"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
variable "vpc_private_subnet" {
  description = "VPC private subnet"
  type        = list(string)
}

variable "vpc_public_subnet" {
  description = "VPC public subnet"
  type        = list(string)
}

variable "tg_arn" {
  description = "target group"
  type        = string
}