output "instance_public_ip" {
  value = aws_instance.web_server_m.public_ip
}