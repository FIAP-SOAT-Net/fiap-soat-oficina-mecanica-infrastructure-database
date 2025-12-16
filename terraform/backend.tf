# Remote State Configuration
# This stores the Terraform state file in S3, enabling state sharing across pipeline runs
# and team members, preventing conflicts and state loss.

terraform {
  backend "s3" {
    bucket         = "smart-workshop-terraform-state-243100982781"
    key            = "database/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "smart-workshop-terraform-locks-243100982781"
  }
}
