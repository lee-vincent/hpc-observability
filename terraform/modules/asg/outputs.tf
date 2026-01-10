output "asg_name" {
  value = aws_autoscaling_group.compute.name
}

output "asg_arn" {
  value = aws_autoscaling_group.compute.arn
}

output "launch_template_id" {
  value = aws_launch_template.compute.id
}
