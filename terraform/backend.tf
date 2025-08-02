# Terraform Backend Configuration
terraform {
  backend "s3" {
    bucket         = "gitops-learning-terraform-state-1753768527"
    key            = "staging/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock-new"
    encrypt        = true
  }
} 