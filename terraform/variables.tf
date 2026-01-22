variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "demo"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "hpc-obs"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "allowed_cidr" {
  description = "CIDR blocks allowed to access bastion (your IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # CHANGE THIS to your IP/32 for security
}

variable "keypair_name" {
  description = "EC2 key pair name (optional if using SSM)"
  type        = string
  default     = ""
}

variable "use_ssm" {
  description = "Use SSM Session Manager for access (recommended)"
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.small"
}

variable "bcm_instance_type" {
  description = "Instance type for BCM head node"
  type        = string
  default     = "t3.large"
}

variable "controller_instance_type" {
  description = "Instance type for Slurm controller"
  type        = string
  default     = "t3.large"
}

variable "db_instance_type" {
  description = "Instance type for MariaDB"
  type        = string
  default     = "t3.medium"
}

variable "observability_instance_type" {
  description = "Instance type for Prometheus/Grafana"
  type        = string
  default     = "t3.large"
}

variable "observability_cloud_init" {
  description = "Cloud-init file to use for observability instance (use observability-minimal.yaml for debugging)"
  type        = string
  default     = "observability.yaml"
}

variable "compute_instance_type" {
  description = "Instance type for GPU compute nodes"
  type        = string
  default     = "g4dn.xlarge"
}

variable "compute_node_count" {
  description = "Number of GPU compute nodes"
  type        = number
  default     = 2
}

variable "compute_node_min" {
  description = "Minimum number of GPU compute nodes in ASG"
  type        = number
  default     = 0
}

variable "compute_node_max" {
  description = "Maximum number of GPU compute nodes in ASG"
  type        = number
  default     = 4
}

variable "db_volume_size" {
  description = "Size of EBS volume for MariaDB in GB"
  type        = number
  default     = 50
}

variable "compute_root_volume_size" {
  description = "Root volume size for compute nodes in GB"
  type        = number
  default     = 100
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "slurm_cluster_name" {
  description = "Name of the Slurm cluster"
  type        = string
  default     = "hpc-demo"
}

variable "enable_spot_instances" {
  description = "Use spot instances for compute nodes (cost savings)"
  type        = bool
  default     = false
}

variable "spot_max_price" {
  description = "Maximum spot price for compute instances (empty = on-demand price)"
  type        = string
  default     = ""
}
