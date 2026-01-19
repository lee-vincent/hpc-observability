resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  iam_instance_profile        = var.bastion_instance_profile
  key_name                    = var.keypair_name != "" ? var.keypair_name : null
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }

  user_data = templatefile("${var.scripts_path}/cloud-init/bastion.yaml", {
    hostname = "bastion"
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion"
    Role = "bastion"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

# resource "aws_instance" "bcm" {
#   ami                    = var.ami_id
#   instance_type          = var.bcm_instance_type
#   subnet_id              = var.private_subnet_id
#   vpc_security_group_ids = [var.bcm_sg_id]
#   iam_instance_profile   = var.bcm_instance_profile
#   key_name               = var.keypair_name != "" ? var.keypair_name : null

#   root_block_device {
#     volume_type           = "gp3"
#     volume_size           = 100
#     delete_on_termination = true
#   }

#   user_data = templatefile("${var.scripts_path}/cloud-init/bcm.yaml", {
#     hostname       = "bcm"
#     environment    = var.environment
#     project_name   = var.project_name
#     cluster_name   = var.slurm_cluster_name
#     controller_ip  = aws_instance.controller.private_ip
#     db_ip          = aws_instance.db.private_ip
#   })

#   tags = merge(var.tags, {
#     Name = "${var.name_prefix}-bcm"
#     Role = "bcm"
#   })

#   lifecycle {
#     ignore_changes = [ami]
#   }

#   depends_on = [aws_instance.controller, aws_instance.db]
# }

# resource "aws_instance" "controller" {
#   ami                    = var.ami_id
#   instance_type          = var.controller_instance_type
#   subnet_id              = var.private_subnet_id
#   vpc_security_group_ids = [var.controller_sg_id]
#   iam_instance_profile   = var.controller_instance_profile
#   key_name               = var.keypair_name != "" ? var.keypair_name : null

#   root_block_device {
#     volume_type           = "gp3"
#     volume_size           = 50
#     delete_on_termination = true
#   }

#   user_data = templatefile("${var.scripts_path}/cloud-init/controller.yaml", {
#     hostname       = "controller"
#     environment    = var.environment
#     project_name   = var.project_name
#     cluster_name   = var.slurm_cluster_name
#     db_ip          = aws_instance.db.private_ip
#   })

#   tags = merge(var.tags, {
#     Name = "${var.name_prefix}-controller"
#     Role = "controller"
#   })

#   lifecycle {
#     ignore_changes = [ami]
#   }

#   depends_on = [aws_instance.db]
# }

# resource "aws_instance" "db" {
#   ami                    = var.ami_id
#   instance_type          = var.db_instance_type
#   subnet_id              = var.private_subnet_id
#   vpc_security_group_ids = [var.db_sg_id]
#   iam_instance_profile   = var.db_instance_profile
#   key_name               = var.keypair_name != "" ? var.keypair_name : null

#   root_block_device {
#     volume_type           = "gp3"
#     volume_size           = var.db_volume_size
#     delete_on_termination = true
#     iops                  = 3000
#     throughput            = 125
#   }

#   user_data = templatefile("${var.scripts_path}/cloud-init/db.yaml", {
#     hostname     = "db"
#     environment  = var.environment
#     project_name = var.project_name
#   })

#   tags = merge(var.tags, {
#     Name = "${var.name_prefix}-db"
#     Role = "db"
#   })

#   lifecycle {
#     ignore_changes = [ami]
#   }
# }

# resource "aws_instance" "observability" {
#   ami                    = var.ami_id
#   instance_type          = var.observability_instance_type
#   subnet_id              = var.private_subnet_id
#   vpc_security_group_ids = [var.observability_sg_id]
#   iam_instance_profile   = var.observability_instance_profile
#   key_name               = var.keypair_name != "" ? var.keypair_name : null

#   root_block_device {
#     volume_type           = "gp3"
#     volume_size           = 100
#     delete_on_termination = true
#   }

#   user_data = templatefile("${var.scripts_path}/cloud-init/observability.yaml", {
#     hostname       = "observability"
#     environment    = var.environment
#     project_name   = var.project_name
#     controller_ip  = aws_instance.controller.private_ip
#   })

#   tags = merge(var.tags, {
#     Name = "${var.name_prefix}-observability"
#     Role = "observability"
#   })

#   lifecycle {
#     ignore_changes = [ami]
#   }

#   depends_on = [aws_instance.controller]
# }
