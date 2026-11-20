provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "terraform-eks-cluster"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
