output "instance_public_ip" {
  value = module.ec2.instance_public_ip
}

output "cloudwatch_log_group" {
  value = module.cloudwatch.log_group_name
}