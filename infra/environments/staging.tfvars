# Staging Environment Configuration

# Environment
environment = "staging"

# Network Configuration
vpc_cidr_block    = "10.1.0.0/16"
public_subnet_cidr = "10.1.1.0/24"
availability_zone  = "ap-southeast-1a"

# Security Configuration
allowed_ssh_cidr_blocks = ["0.0.0.0/0"]
allowed_http_cidr_blocks = ["0.0.0.0/0"]
allowed_database_cidr_blocks = ["0.0.0.0/0"]
expose_database_ports = true

# EC2 Configuration
instance_type = "t3.micro"
root_volume_size = 20
root_volume_type = "gp3"
encrypt_volumes = false
allocate_eip = false

# SSH Configuration
instance_password = "Ubuntu2024!"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD4r4uE1Crhd7+qbBzy/l9eSbQqi/5R6KKeJNzNETvbZqsyqjgNhcS6J7V58CWHImm+OpUFL6gTd0Q+pXXv23Rn7LujFxDBAXxFW8rR8N7osvX0jkReRQgCEijT7gcgkoy0gmrkB/DSyKFnThVnzhDPaqrSHoZX8ixnvNjDd5yJ+o4dROaT9+jLeiBcyjogob3DK66H/4xO8yQrrEmw6v1j5iu+H8vk63wYKKEhRD8TfOu4K27FfYTN53wCB5mDOJhXJniSxHIXLGzsKMnoXRZJsspgDzRR/QdQQrz2Vfb2UICo0rnFgnsSRcjg+vPLi2YcmZ7h5ZaMvf5ww9KTI7c9hiEigbe1ptqSQg7OqbjYcn0H+WI4Tkr9qKapkxYLWsHVd9NP/56RVpdf3kP4MJauU1oiRaXCq51rxDz4xTTshWjW60fej6yg7hP0ZQ9yLQaNaLIgpiYuBXJf4psMRCIvyebxLQPfQWXVrJMM/PHJwZ2qNgO9u5Ijv0tszKjT426BuAGhr01an4i76qI2/M0eDi+j6GXDF50naU+5HzMDPnR6OKMr6kC4zVVHEEDAM8c5HQLgbupvnW4dMcDhET5LIk2ad2J3405vDwSDoVxw2oWz31nMfX9jl1tWjKzricXytk4JWAQgQ6MAlikbR2ZDb+O+A1n1pEJrI497G9sIrw== gitops-learning@20250729" 