# Staging Environment Variables
environment = "staging"
instance_type = "t3.micro"
ami_id = "ami-0fa377108253bf620"  # Ubuntu 22.04 LTS in ap-southeast-1

# Network Configuration
vpc_cidr = "10.1.0.0/16"
subnet_cidr = "10.1.1.0/24"

# Tags
project = "gitops-learning"
environment = "staging" 