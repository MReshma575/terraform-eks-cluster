variable "region" {
  description = "AWS region to deploy the cluster into"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "demo-eks"
}

variable "environment" {
  description = "Environment label used for tagging (dev, qa, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "CIDR block for the cluster VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "app_instance_types" {
  description = "Instance types for the application node group"
  type        = list(string)
  default     = ["t3.large"]
}

variable "app_desired_capacity" {
  description = "Desired number of application nodes"
  type        = number
  default     = 3
}

variable "app_min_capacity" {
  description = "Minimum number of application nodes"
  type        = number
  default     = 2
}

variable "app_max_capacity" {
  description = "Maximum number of application nodes"
  type        = number
  default     = 6
}
