variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {}

variable "availability_zone" {
  default = "eu-west-1b"
}
variable "private_subnet_cidr" {
  default = "10.0.1.0/24"
}
variable "aws_key_name" {
  default = "AWSKeyPair"
}
variable "public_key_path" {
  default = "~/Desktop/AWSKeyPair.pub"
}
variable "instance_type" {
  default = "t1.micro"
}
variable "aws_nat_ami" {
  default = "ami-cb7de3bc"
  #default = "ami-8fcee4e5"
}
variable "aws_ubuntu_ami" {
  default = "ami-f3810f84"
  #default = "ami-fce3c696"
}

variable "aws_region" {
    description = "EC2 Region for the VPC"
    default = "eu-west-1"
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
    description = "CIDR for the Public Subnet"
    default = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
    description = "CIDR for the Private Subnet"
    default = "10.0.1.0/24"
}
