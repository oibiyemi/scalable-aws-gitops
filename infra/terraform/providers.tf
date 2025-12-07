# Providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    # Kubenetes Provider
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

}

# Configure the GitHub Provider
# Secuirty Risk: Do NOT: Create a variable "github_token"
# GitHub Provider automatically looks for environment variable named GITHUB_TOKEN
provider "github" {
  owner = var.github_owner
}

# Pulls the region from input variable
provider "aws" {
  region = var.aws_region
}
# ===========================================================================================================
# When initializing the Kubernetes provider, we must be able to reference 
# the live attributes of a fully provisioned EKS cluster.
#   1. **Where is the cluster?**  
#      → We must give the provider the live EKS endpoint.  
#        Without this, Terraform does not know which API server to talk to.
#   2. **Who is the cluster? (Prove its identity)**  
#      → We must give the Cluster CA Certificate.  
#        This is how Terraform verifies that the API server it is talking to
#        is the *real* EKS cluster and not an imposter.
#        (TLS trust: “I know this is the correct cluster because I trust this CA.”)
#   3. **How do we log in?**  
#      → We use `aws eks get-token` to generate a temporary IAM-authenticated token.  
#        Without this, Terraform cannot authenticate and the provider fails.
#   4. **Does the cluster exist yet?**  
#      → It MUST be created first.  
#        If Terraform tries to initialize the provider before EKS exists,
#        Terraform will throw:  
#           “Failed to configure Kubernetes client… cannot connect…”
# ===========================================================================================================

# Configure Kubenetes Provider
provider "kubernetes" {

  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  # ==============================================================================
  # EKS generates short-lived authentication tokens that expire relatively quickly. 
  # To ensure the Kubernetes provider is receiving valid credentials, 
  # we are using exec plugin to fetch a new token before each Terraform operation
  # ==============================================================================
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Helm Provider
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}
