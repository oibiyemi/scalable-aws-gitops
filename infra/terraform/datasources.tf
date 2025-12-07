# Get Account ID
data "aws_caller_identity" "current" {}

# Get AWS Region
data "aws_region" "region" {

}
