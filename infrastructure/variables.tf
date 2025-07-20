variable "aws_region" {
  default = "eu-central-1"
}

variable "profile" {
  default = "default"
}

variable "ami" {
  default = "ami-09042b2f6d07d164a"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_pair_name" {
  default = "margarita_key"
}

variable "instance_name" {
  default = "EC2TerraformMargarita"
}

variable "my_ip" {
  description = "Your public IP"
  default     = "176.4.179.5/32"
}