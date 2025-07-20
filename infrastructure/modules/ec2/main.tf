resource "aws_security_group" "ec2_sg_m" {
  name        = "ec2_sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.security_group_cidr_ip]
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
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  security_groups        = [aws_security_group.ec2_sg_m.name]
  associate_public_ip_address = true
  iam_instance_profile   = var.iam_instance_profile

  tags = {
    Name = var.instance_name
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd amazon-cloudwatch-agent
              systemctl start httpd
              systemctl enable httpd
              echo "Hello, World!" > /var/www/html/index.html

              cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json <<CONFIG
              {
                "agent": {
                  "metrics_collection_interval": 60,
                  "run_as_user": "root"
                },
                "logs": {
                  "logs_collected": {
                    "files": {
                      "collect_list": [
                        {
                          "file_path": "/var/log/messages",
                          "log_group_name": "/ec2/webserver/messages",
                          "log_stream_name": "{instance_id}"
                        }
                      ]
                    }
                  }
                }
              }
              CONFIG

              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \\
                -a fetch-config -m ec2 \\
                -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
              EOF
}