output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "bcm_private_ip" {
  value = aws_instance.bcm.private_ip
}

output "bcm_instance_id" {
  value = aws_instance.bcm.id
}

output "controller_private_ip" {
  value = aws_instance.controller.private_ip
}

output "controller_instance_id" {
  value = aws_instance.controller.id
}

output "db_private_ip" {
  value = aws_instance.db.private_ip
}

output "db_instance_id" {
  value = aws_instance.db.id
}

output "observability_private_ip" {
  value = aws_instance.observability.private_ip
}

output "observability_instance_id" {
  value = aws_instance.observability.id
}
