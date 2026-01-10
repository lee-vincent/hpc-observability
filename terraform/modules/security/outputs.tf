output "bastion_sg_id" {
  description = "Bastion security group ID"
  value       = aws_security_group.bastion.id
}

output "bcm_sg_id" {
  description = "BCM security group ID"
  value       = aws_security_group.bcm.id
}

output "controller_sg_id" {
  description = "Controller security group ID"
  value       = aws_security_group.controller.id
}

output "db_sg_id" {
  description = "Database security group ID"
  value       = aws_security_group.db.id
}

output "observability_sg_id" {
  description = "Observability security group ID"
  value       = aws_security_group.observability.id
}

output "compute_sg_id" {
  description = "Compute security group ID"
  value       = aws_security_group.compute.id
}
