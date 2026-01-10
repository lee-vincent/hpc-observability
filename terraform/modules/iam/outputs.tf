output "bastion_instance_profile" {
  description = "Bastion instance profile name"
  value       = aws_iam_instance_profile.bastion.name
}

output "bcm_instance_profile" {
  description = "BCM instance profile name"
  value       = aws_iam_instance_profile.bcm.name
}

output "controller_instance_profile" {
  description = "Controller instance profile name"
  value       = aws_iam_instance_profile.controller.name
}

output "db_instance_profile" {
  description = "Database instance profile name"
  value       = aws_iam_instance_profile.db.name
}

output "observability_instance_profile" {
  description = "Observability instance profile name"
  value       = aws_iam_instance_profile.observability.name
}

output "compute_instance_profile" {
  description = "Compute instance profile name"
  value       = aws_iam_instance_profile.compute.name
}
