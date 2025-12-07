# AWS VPC Terraform module
# VPC: 2-AZ architecture with Public/Private subnets.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.0" # Always pin module versions!

  name = var.cluster_name
  cidr = var.vpc_cidr

  azs             = var.availabilty_zones
  private_subnets = local.private
  public_subnets  = local.public

  # Uses Single NAT Gateway strategy to save costs (Private nodes(internet access) -> NAT -> IGW).
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # Required tags for EKS
  # These tags MUST exist on subnets for EKS to function
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}
