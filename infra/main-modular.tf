provider "aws" {
  region = var.aws_region
}

# Common tags for all resources
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block    = var.vpc_cidr_block
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
  environment        = var.environment
  common_tags        = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"

  vpc_id                    = module.vpc.vpc_id
  environment              = var.environment
  allowed_ssh_cidr_blocks  = var.allowed_ssh_cidr_blocks
  allowed_http_cidr_blocks = var.allowed_http_cidr_blocks
  allowed_database_cidr_blocks = var.allowed_database_cidr_blocks
  expose_database_ports    = var.expose_database_ports
  common_tags              = local.common_tags
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"

  ami_id              = var.ami_id
  instance_type       = var.instance_type
  subnet_id           = module.vpc.public_subnet_id
  security_group_ids  = [module.security_groups.security_group_id]
  key_name            = var.key_name
  root_volume_size    = var.root_volume_size
  root_volume_type    = var.root_volume_type
  encrypt_volumes     = var.encrypt_volumes
  environment         = var.environment
  ssh_public_key      = var.ssh_public_key
  instance_password   = var.instance_password
  allocate_eip        = var.allocate_eip
  common_tags         = local.common_tags
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.security_groups.security_group_id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.instance_public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = module.ec2.instance_private_ip
}

output "eip_public_ip" {
  description = "Elastic IP address if allocated"
  value       = module.ec2.eip_public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = module.ec2.ssh_command
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    environment     = var.environment
    instance_ip     = module.ec2.instance_public_ip
    eip_ip          = module.ec2.eip_public_ip
    ssh_command     = module.ec2.ssh_command
    frontend_url    = "http://${module.ec2.instance_public_ip}:8080"
    user_api_url    = "http://${module.ec2.instance_public_ip}:5001"
    product_api_url = "http://${module.ec2.instance_public_ip}:5002"
    order_api_url   = "http://${module.ec2.instance_public_ip}:5003"
  }
} 