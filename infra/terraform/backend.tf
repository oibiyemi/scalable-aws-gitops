terraform {
  backend "s3" {
    bucket         = "tfstate-7b1359be-8887-4e2e-8b28-7f87edf50b95"
    key            = "env/dev/terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

}
