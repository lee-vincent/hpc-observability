variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "keypair_name" {
  type    = string
  default = ""
}

variable "instance_type" {
  type = string
}

variable "root_volume_size" {
  type = number
}

variable "desired_capacity" {
  type = number
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "security_group_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "controller_ip" {
  type = string
}

variable "bcm_ip" {
  type = string
}

variable "observability_ip" {
  type = string
}

variable "slurm_cluster_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "enable_spot" {
  type    = bool
  default = false
}

variable "spot_max_price" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "scripts_path" {
  description = "Path to scripts directory"
  type        = string
}
