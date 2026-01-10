provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "hpc-observability"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
