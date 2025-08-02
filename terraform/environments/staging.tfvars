# Staging Environment Configuration
environment = "staging"
aws_region  = "ap-southeast-1"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

# EKS Configuration
kubernetes_version = "1.28"
node_group_desired_capacity = 2
node_group_max_size         = 3
node_group_min_size         = 1
node_group_instance_types   = ["t3.small"]  # Minimum for EKS add-ons

# Application Repositories
app_repositories = [
  "user-service",
  "product-service",
  "order-service", 
  "frontend"
]

# Common Tags
common_tags = {
  Environment = "staging"
  Project     = "gitops-learning"
  ManagedBy   = "terraform"
  Owner       = "devops-team"
  CostCenter  = "engineering"
} 