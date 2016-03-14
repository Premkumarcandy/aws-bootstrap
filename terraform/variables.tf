variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {}
variable "aws_key_name" {
        default = "AWSKeyPair"
}
variable "public_key_path" {
        default = "~/Desktop/AWSKeyPair.pub"
}
variable "aws_nat_ami" {
	default = "ami-cb7de3bc"
}
variable "aws_ubuntu_ami" {
	default = "ami-f3810f84"
}
