terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  ami           = "ami-09042b2f6d07d164a"
  instance_type = "t2.micro"

  tags = {
    Name = "grocerymate-ec2"
  }
}

