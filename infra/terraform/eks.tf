#================================================================================
# EKS MODULE - IAM ROLE STRATEGY
#================================================================================
# DECISION: Let the EKS module create and manage cluster and node IAM roles
#
# REASONING:
# - Cluster-level and node-level IAM roles contain zero application business logic
# - These roles are tightly coupled to EKS internals and AWS-managed policies
# - AWS frequently updates required permissions as EKS evolves (new features, 
#   security patches, API changes)
# - The module stays current with AWS best practices and permission requirements
# - Reduces maintenance burden and eliminates permission debugging
#
# WHAT THE MODULE CREATES:
# 1. EKS Cluster IAM Role with policies:
#    - AmazonEKSClusterPolicy
#    - AmazonEKSVPCResourceController (for VPC management)
#
# 2. EKS Node Group IAM Role with policies:
#    - AmazonEKSWorkerNodePolicy (EC2/EKS integration)
#    - AmazonEKS_CNI_Policy (Pod networking)
#    - AmazonEC2ContainerRegistryReadOnly (Pull images from ECR)
#
# APPLICATION-LEVEL IAM:
# For application workloads, we create custom IRSA (IAM Roles for Service Accounts)
# roles separately. This gives us:
# - Fine-grained, least-privilege access per application
# - Clear separation between infrastructure and application permissions
# - Full control over what each pod can access in AWS
# - Better security posture and audit trails
#
#================================================================================

# ==========================================================================================================
# PUBLIC API ENDPOINT — GitOps & Security Strategy
# ==========================================================================================================
# 1. PUBLIC ACCESS (Why we keep it 'true'):
#    We enable the public endpoint so YOU (the engineer) can manage the cluster via kubectl/Terraform
#    from your workstation or WSL without needing a complex Bastion Host/VPN setup.
#
# 2. CIDR RESTRICTIONS (The "Allowlist"):
#    - In a PUSH model (GitHub Actions -> Cluster), we would need to whitelist GitHub Runner IPs.
#    - In this GITOPS PULL model (ArgoCD), the deployer lives INSIDE the cluster.
#      ArgoCD uses the private internal endpoint. GitHub Actions NEVER talks to the cluster.
#
# 3. PROD BEST PRACTICE:
#    If 'endpoint_public_access = true', strictly limit CIDRs to:
#      - Corporate VPN / Office IPs
#      - Management Bastion Host IP
#   
# Do not leave the door wide open (0.0.0.0/0).
# List only Corporate VPN, Bastion Host, and CI/CD Runner IPs.
# cluster_endpoint_public_access_cidrs = ["1.2.3.4/32", "192.168.0.0/24"]

#    *NEVER* whitelist dynamic GitHub Runner IPs in Prod (security risk). 
#    If CI needs access, use Self-Hosted Runners inside the VPC.
#
# Current Config: Open to 0.0.0.0/0 for portfolio demonstration only.
# ==========================================================================================================



module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = "1.30"

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }
  create_iam_role      = true
  create_node_iam_role = true

  # Enables EKS private API server endpoint
  # MANDATORY for GitOps Performance
  # Allows ArgoCD and Worker Nodes to talk to the API securely inside AWS.
  endpoint_private_access = true

  # CRITICAL for YOU (Terraform/Kubectl)
  # YOU need this door open.
  endpoint_public_access = true

  # 3. PRODUCTION SECURITY LOCKDOWN (Recommended but Disabled for Portfolio)
  # --------------------------------------------------------------------------
  # In a real FAANG/Enterprise environment, we NEVER leave the public endpoint 
  # open to the entire internet (0.0.0.0/0). We restrict access to trusted 
  # corporate networks only.
  #
  # Since this is a portfolio project running on a dynamic home IP, these 
  # restrictions are commented out to prevent accidental lockout.
  #
  # cluster_endpoint_public_access_cidrs = [
  #   "203.0.113.5/32",  # Example: Corporate Office Static IP
  #   "198.51.100.0/24", # Example: Corporate VPN Range
  #   "10.0.0.5/32",     # Example: Management Bastion Host IP
  # ]




  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id = module.vpc.vpc_id
  # Subnet Where Worker Nodes (EC2 instances) will be launched.
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    worker_nodes = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.cluster_instance_type]

      min_size     = 2
      max_size     = 10
      desired_size = 2

      # Capacity Type: SPOT instances save 70% more money!
      capacity_type = "SPOT"
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}
