
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