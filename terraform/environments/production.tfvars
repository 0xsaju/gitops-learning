# Production Environment Configuration
environment = "production"
aws_region  = "ap-southeast-1"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

# EKS Configuration
kubernetes_version = "1.28"
node_group_desired_capacity = 2
node_group_max_size         = 4
node_group_min_size         = 2
node_group_instance_types   = ["t3.small", "t3.medium"]

# Application Repositories
app_repositories = [
  "user-service",
  "product-service",
  "order-service", 
  "frontend"
]

# Common Tags
common_tags = {
  Environment = "production"
  Project     = "gitops-learning"
  ManagedBy   = "terraform"
  Owner       = "devops-team"
  CostCenter  = "engineering"
} 