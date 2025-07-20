provider "aws" {
    region  = var.aws_region
    profile = var.profile
}

resource "aws_security_group" "web_sg_m" {
    name        = "web_sg"
    description = "Allow HTTP and SSH traffic"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["176.4.179.5/32"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "web_server_m" {
    ami = var.ami
    instance_type               = var.instance_type
    key_name                    = var.key_pair_name
    security_groups             = [aws_security_group.web_sg_m.name]
    associate_public_ip_address = true

    tags = {
        Name = var.instance_name
    }

    user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello, World!" › /var/www/html/index.html
              EOF
}
