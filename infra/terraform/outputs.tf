#======================================================================
# outputs.tf
#======================================================================
# 1. Critical for the Kubernetes Provider
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

# 2. Critical for the Kubernetes Provider (TLS Verification)
output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

# 3. Critical for AWS CLI & Helm and Kubernetes Provider Auth
output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

# 4. Critical for IRSA (IAM Roles for Service Accounts)
output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enable_irsa = true"
  value       = module.eks.oidc_provider_arn
}

# 5. Configure kubectl to talk to our new EKS cluster
output "configure_kubectl" {
  description = "Configure kubectl: run this command in your terminal"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# 6. Output Account ID
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

# 7. Output AWS Region
output "aws_region" {
  value = data.aws_region.region
}
