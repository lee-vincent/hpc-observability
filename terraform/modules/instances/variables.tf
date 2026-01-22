variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for instances"
  type        = string
}

variable "keypair_name" {
  description = "EC2 key pair name"
  type        = string
  default     = ""
}

variable "bastion_instance_type" {
  type = string
}

variable "bcm_instance_type" {
  type = string
}

variable "controller_instance_type" {
  type = string
}

variable "db_instance_type" {
  type = string
}

variable "observability_instance_type" {
  type = string
}

variable "db_volume_size" {
  type = number
}

variable "bastion_sg_id" {
  type = string
}

variable "bcm_sg_id" {
  type = string
}

variable "controller_sg_id" {
  type = string
}

variable "db_sg_id" {
  type = string
}

variable "observability_sg_id" {
  type = string
}

variable "bastion_instance_profile" {
  type = string
}

variable "bcm_instance_profile" {
  type = string
}

variable "controller_instance_profile" {
  type = string
}

variable "db_instance_profile" {
  type = string
}

variable "observability_instance_profile" {
  type = string
}

variable "slurm_cluster_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "scripts_path" {
  description = "Path to scripts directory"
  type        = string
}

variable "observability_cloud_init" {
  description = "Cloud-init file to use for observability instance"
  type        = string
  default     = "observability.yaml"
}

variable "bcm_cloud_init" {
  description = "Cloud-init file to use for BCM instance"
  type        = string
  default     = "bcm.yaml"
}
