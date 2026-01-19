output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = module.instances.bastion_public_ip
}

output "bastion_instance_id" {
  description = "Instance ID of bastion for SSM access"
  value       = module.instances.bastion_instance_id
}

# output "bcm_private_ip" {
#   description = "Private IP of BCM head node"
#   value       = module.instances.bcm_private_ip
# }

# output "controller_private_ip" {
#   description = "Private IP of Slurm controller"
#   value       = module.instances.controller_private_ip
# }

# output "db_private_ip" {
#   description = "Private IP of MariaDB instance"
#   value       = module.instances.db_private_ip
# }

# output "observability_private_ip" {
#   description = "Private IP of Prometheus/Grafana instance"
#   value       = module.instances.observability_private_ip
# }

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = module.vpc.private_subnet_id
}

# output "grafana_access" {
#   description = "How to access Grafana"
#   value       = <<-EOT
#     Via SSM port forward:
#       aws ssm start-session --target ${module.instances.bastion_instance_id} \
#         --document-name AWS-StartPortForwardingSessionToRemoteHost \
#         --parameters '{"host":["${module.instances.observability_private_ip}"],"portNumber":["3000"],"localPortNumber":["3000"]}'
#     Then open: http://localhost:3000 (admin/admin initially, change on first login)
#   EOT
# }

# output "prometheus_access" {
#   description = "How to access Prometheus"
#   value       = <<-EOT
#     Via SSM port forward:
#       aws ssm start-session --target ${module.instances.bastion_instance_id} \
#         --document-name AWS-StartPortForwardingSessionToRemoteHost \
#         --parameters '{"host":["${module.instances.observability_private_ip}"],"portNumber":["9090"],"localPortNumber":["9090"]}'
#     Then open: http://localhost:9090
#   EOT
# }

# output "bcm_ui_access" {
#   description = "How to access BCM web UI"
#   value       = <<-EOT
#     Via SSM port forward:
#       aws ssm start-session --target ${module.instances.bastion_instance_id} \
#         --document-name AWS-StartPortForwardingSessionToRemoteHost \
#         --parameters '{"host":["${module.instances.bcm_private_ip}"],"portNumber":["8081"],"localPortNumber":["8081"]}'
#     Then open: https://localhost:8081
#   EOT
# }

# output "slurm_controller_hostname" {
#   description = "Slurm controller hostname"
#   value       = "controller.${var.project_name}.internal"
# }

output "ssm_connect_bastion" {
  description = "Command to connect to bastion via SSM"
  value       = "aws ssm start-session --target ${module.instances.bastion_instance_id}"
}

# output "ssh_config_snippet" {
#   description = "SSH config for access through bastion"
#   value       = <<-EOT
#     # Add to ~/.ssh/config
#     Host bastion-${var.project_name}
#       HostName ${module.instances.bastion_public_ip}
#       User ubuntu
#       IdentityFile ~/.ssh/your-key.pem

#     Host bcm-${var.project_name}
#       HostName ${module.instances.bcm_private_ip}
#       User ubuntu
#       ProxyJump bastion-${var.project_name}

#     Host controller-${var.project_name}
#       HostName ${module.instances.controller_private_ip}
#       User ubuntu
#       ProxyJump bastion-${var.project_name}

#     Host observability-${var.project_name}
#       HostName ${module.instances.observability_private_ip}
#       User ubuntu
#       ProxyJump bastion-${var.project_name}
#   EOT
# }

output "db_credentials_ssm_path" {
  description = "SSM Parameter Store path for DB credentials"
  value       = "/hpc-obs/${var.environment}/db"
}

output "munge_key_ssm_path" {
  description = "SSM Parameter Store path for Munge key"
  value       = "/hpc-obs/${var.environment}/munge-key"
}
