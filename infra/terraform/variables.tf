#================================================================================
# variables.tf - Variable Blocks
#================================================================================


# AWS Region Variable Block
variable "aws_region" {
  description = "The AWS region to deploy infrastructure in."
  type        = string

  # Check if the provided region is in the following list of common regions
  validation {
    condition = contains(["us-west-1", "us-west-2",
    "ca-central-1"], var.aws_region)
    error_message = "The AWS region must be allowed in the var.aws_region block."
  }

}

# Github Owner 
variable "github_owner" {
  description = "The target GitHub organization or personal username."
  type        = string

  validation {
    condition     = length(var.github_owner) > 0
    error_message = "Github org/username cannot be empty."
  }
}

# VPC CIDR Variable Block
variable "vpc_cidr" {
  description = "The CIDR block for our VPC."
  type        = string

  # Check if VPC CIDR is assignable
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Invalid CIDR. Must be a valid IPV4 Cidr Block."

  }
}

# EKS instance type
variable "cluster_instance_type" {
  description = "EC2 instance type for the EKS nodes."
  type        = string

  # Constrain instance types allowed for cost management
  validation {
    condition = contains([
      "t3.medium",
      "t3a.small",
    "t3a.medium"], var.cluster_instance_type)
    error_message = "Invalid EKS instance type. Allowed values: t3a.small, t3a.medium, t3.medium."

  }
}

# Cluster identification
variable "cluster_name" {
  description = "The name for our EKS cluster."
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "Cluster name cannot be empty."
  }
}

# List of Availability Zones
variable "availabilty_zones" {
  description = "List of AZs for high availability."
  type        = list(string)

  # Check if VPC CIDR is assignable
  validation {
    # 1. Check: Must have more than one AZ
    condition     = length(var.availabilty_zones) >= 2
    error_message = "Provide at least 2 AZs for high availability."
  }
}


# App Name
variable "app_name" {
  description = "Name of the application requiring AWS access"
  type        = string
  default     = "my-app"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.app_name))
    error_message = "App name must contain only lowercase letters, numbers, and hyphens."
  }
}


# Environment Variable Block 
variable "environment" {
  description = "Environment name (maps to Kubernetes namespace)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}


# # Account ID Variable
# variable "account_id" {
#   description = "AWS Account ID"
#   type        = string

#   validation {
#     condition     = can(regex("^[0-9-]+$", var.account_id))
#     error_message = "Account Id must contain numbers and hyphens."
#   }
# }

variable "irsa_app_configs" {
  description = "Configuration for all IRSA-enabled applications"
  type = map(object({
    namespace       = string
    service_account = string


    iam_policies = map(object({
      sid              = string
      actions          = list(string)
      resource_service = string
      resource_paths   = list(string)

    }))
  }))
}
