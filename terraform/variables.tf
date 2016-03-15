variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {}
variable "region" {
  default = "eu-west-1"
}
variable "availability_zone" {
  default = "eu-west-1b"
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
