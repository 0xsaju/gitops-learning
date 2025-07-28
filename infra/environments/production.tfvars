# Production Environment Configuration

# Environment
environment = "production"

# Network Configuration
vpc_cidr_block    = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
availability_zone  = "ap-southeast-1a"

# Security Configuration
allowed_ssh_cidr_blocks = ["0.0.0.0/0"]
allowed_http_cidr_blocks = ["0.0.0.0/0"]
allowed_database_cidr_blocks = ["10.0.0.0/16"]  # Restrict to VPC only
expose_database_ports = false

# EC2 Configuration
instance_type = "t3.small"
root_volume_size = 30
root_volume_type = "gp3"
encrypt_volumes = true
allocate_eip = true

# SSH Configuration
instance_password = "Ubuntu2024!"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3EXAMPLEKEYHERE user@host" 