#================================================================================
# IRSA - Application Policy Configuration
#================================================================================


# APP - IAM Role Permission Policy
resource "aws_iam_policy" "policy" {
  for_each    = local.iam_policies
  name        = "${each.key}-policy"
  description = "Permission policy - Defines what the ${each.key} service identity can do."

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Sid    = each.value.sid
        Action = each.value.actions
        Effect = "Allow"
        Resource = [for path in each.value.resource_paths :
          "arn:aws:${each.value.resource_service}:${local.region}:${local.account_id}:${path}"
        ]
      }
    ]
  })
}


# IAM Role for Service Accounts in EKS
# This tells IAM to trust OIDC Provider tokens from our EKS cluster.
# without storing long-lived keys.
module "iam_eks_role" {

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.52"

  for_each  = var.irsa_app_configs
  role_name = "${each.key}-irsa-role"
  #------------------------------------------------------------------------------------
  # App Permission policy 
  # This answers: "What can this pod do?" (e.g., Read GetSecret from SecretsManager)
  # You define the custom permissions the app needs and then reference it here
  # api-service-secrets-read and api-service-kms-decrypt
  #------------------------------------------------------------------------------------
  role_policy_arns = {
    for policy_name, policy_cfg in each.value.iam_policies :
    policy_name => aws_iam_policy.policy["${each.key}-${policy_name}"].arn
  }
  # The Federated Trust 
  # This value comes AUTOMATICALLY from your EKS module output. Needs to be referenced
  # Check Attribute documentation for possible outputs
  oidc_providers = {
    one = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${each.value.namespace}:${each.value.service_account}"]
    }
  }
}

# Create Namespace for the IRSA
# AVOID Namespace Collision
# Uniqueness: We must create the namespace resource only once
# even if 10 applications use the same "api" namespace
# Iterate over ["api", "monitoring", "etc"]
resource "kubernetes_namespace" "apps" {
  for_each = local.unique_namespaces
  metadata {
    labels = {
      ManagedBy = "Terraform"
    }
    name = each.key
  }
  # Wait for cluster to be ready
  depends_on = [module.eks]
}

# Create Service Account for IRSA
resource "kubernetes_service_account" "app_service_account" {
  for_each = var.irsa_app_configs
  metadata {
    name      = each.value.service_account
    namespace = each.value.namespace
    # Connects this K8s Service Account to the AWS IAM Role.
    # It allows Pods using this account to assume the role and access AWS resources.  
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_eks_role[each.key].iam_role_arn
    }
  }
  # Wait for the cluster to exist!
  depends_on = [module.eks]
}

