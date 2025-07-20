output "iam_instance_profile_name" {
  value = aws_iam_instance_profile.cloudwatch_profile.name
}

output "log_group_name" {
  value = "/ec2/webserver/messages"
}