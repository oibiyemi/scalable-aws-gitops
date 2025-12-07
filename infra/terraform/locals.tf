# Account Attributes
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = var.aws_region

  # Extract and deduplicate the namespaces
  # This ensures that even if 50 apps use the "api" namespace, 
  # Terraform only tries to create it once.
  unique_namespaces = toset(distinct([
    for app_cfg in var.irsa_app_configs :
    app_cfg.namespace
  ]))
}


# Calculates the subnet addresses from VPC CIDR -> cidrsubnet(prefix, newbits, netnum)
locals {
  newbits = 4
  public = [cidrsubnet(var.vpc_cidr, local.newbits, 0),
  cidrsubnet(var.vpc_cidr, local.newbits, 1)]

  private = [cidrsubnet(var.vpc_cidr, local.newbits, 2),
  cidrsubnet(var.vpc_cidr, local.newbits, 3)]

}

# Flatten nested iam_policies to a single map
locals {
  iam_policies = {
    for items in flatten([
      for app, policies in var.irsa_app_configs : [
        for k, v in policies.iam_policies : {
          app_name         = app
          policy_name      = k
          sid              = v.sid
          actions          = v.actions
          resource_service = v.resource_service
          resource_paths   = v.resource_paths

          key = "${app}-${k}"
        }
      ]
      ]) : items.key => {
      app_name         = items.app_name
      policy_name      = items.policy_name
      sid              = items.sid
      actions          = items.actions
      resource_service = items.resource_service
      resource_paths   = items.resource_paths
    }
  }
}
