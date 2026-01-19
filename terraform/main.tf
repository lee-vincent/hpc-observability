locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "random_password" "grafana_password" {
  length  = 16
  special = false
}

resource "random_id" "munge_key" {
  byte_length = 1024
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/hpc-obs/${var.environment}/db/password"
  description = "MariaDB password for Slurm accounting"
  type        = "SecureString"
  value       = random_password.db_password.result

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_user" {
  name        = "/hpc-obs/${var.environment}/db/user"
  description = "MariaDB username for Slurm accounting"
  type        = "String"
  value       = "slurm"

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/hpc-obs/${var.environment}/db/name"
  description = "MariaDB database name for Slurm accounting"
  type        = "String"
  value       = "slurm_acct_db"

  tags = local.common_tags
}

resource "aws_ssm_parameter" "munge_key" {
  name        = "/hpc-obs/${var.environment}/munge-key"
  description = "Munge authentication key"
  type        = "SecureString"
  value       = random_id.munge_key.b64_std

  tags = local.common_tags
}

resource "aws_ssm_parameter" "grafana_password" {
  name        = "/hpc-obs/${var.environment}/grafana/admin-password"
  description = "Grafana admin password"
  type        = "SecureString"
  value       = random_password.grafana_password.result

  tags = local.common_tags
}

module "vpc" {
  source = "./modules/vpc"

  name_prefix       = local.name_prefix
  vpc_cidr          = var.vpc_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = local.common_tags
}

module "security" {
  source = "./modules/security"

  name_prefix   = local.name_prefix
  vpc_id        = module.vpc.vpc_id
  vpc_cidr      = var.vpc_cidr
  allowed_cidr  = var.allowed_cidr
  tags          = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  name_prefix = local.name_prefix
  environment = var.environment
  use_ssm     = var.use_ssm
  tags        = local.common_tags
}

module "instances" {
  source = "./modules/instances"

  name_prefix                 = local.name_prefix
  environment                 = var.environment
  vpc_id                      = module.vpc.vpc_id
  public_subnet_id            = module.vpc.public_subnet_id
  private_subnet_id           = module.vpc.private_subnet_id
  ami_id                      = data.aws_ami.ubuntu_24_04.id
  keypair_name                = var.keypair_name
  
  bastion_instance_type       = var.bastion_instance_type
  bcm_instance_type           = var.bcm_instance_type
  controller_instance_type    = var.controller_instance_type
  db_instance_type            = var.db_instance_type
  observability_instance_type = var.observability_instance_type
  db_volume_size              = var.db_volume_size
  
  bastion_sg_id               = module.security.bastion_sg_id
  bcm_sg_id                   = module.security.bcm_sg_id
  controller_sg_id            = module.security.controller_sg_id
  db_sg_id                    = module.security.db_sg_id
  observability_sg_id         = module.security.observability_sg_id
  
  bastion_instance_profile    = module.iam.bastion_instance_profile
  bcm_instance_profile        = module.iam.bcm_instance_profile
  controller_instance_profile = module.iam.controller_instance_profile
  db_instance_profile         = module.iam.db_instance_profile
  observability_instance_profile = module.iam.observability_instance_profile
  
  slurm_cluster_name          = var.slurm_cluster_name
  project_name                = var.project_name
  scripts_path                = "${path.root}/../scripts"
  
  tags                        = local.common_tags
}

# module "compute_asg" {
#   source = "./modules/asg"

#   name_prefix              = local.name_prefix
#   environment              = var.environment
#   private_subnet_id        = module.vpc.private_subnet_id
#   ami_id                   = data.aws_ami.ubuntu_24_04.id
#   keypair_name             = var.keypair_name
  
#   instance_type            = var.compute_instance_type
#   root_volume_size         = var.compute_root_volume_size
#   desired_capacity         = var.compute_node_count
#   min_size                 = var.compute_node_min
#   max_size                 = var.compute_node_max
  
#   security_group_id        = module.security.compute_sg_id
#   instance_profile_name    = module.iam.compute_instance_profile
  
#   controller_ip            = module.instances.controller_private_ip
#   bcm_ip                   = module.instances.bcm_private_ip
#   observability_ip         = module.instances.observability_private_ip
#   slurm_cluster_name       = var.slurm_cluster_name
#   project_name             = var.project_name
  
#   enable_spot              = var.enable_spot_instances
#   spot_max_price           = var.spot_max_price
#   scripts_path             = "${path.root}/../scripts"
  
#   tags                     = local.common_tags
# }
