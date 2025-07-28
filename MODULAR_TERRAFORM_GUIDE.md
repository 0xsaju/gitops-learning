# Modular Terraform Infrastructure Guide

## Overview

This guide describes the modular Terraform infrastructure approach for the Flask microservices application. The modular design provides better maintainability, reusability, and separation of concerns across different environments.

## Architecture

### Module Structure

```
infra/
├── modules/
│   ├── vpc/
│   │   ├── main.tf          # VPC, subnets, internet gateway, route tables
│   │   ├── variables.tf     # VPC module variables
│   │   └── outputs.tf       # VPC module outputs
│   ├── security-groups/
│   │   ├── main.tf          # Security group definitions
│   │   ├── variables.tf     # Security group variables
│   │   └── outputs.tf       # Security group outputs
│   └── ec2/
│       ├── main.tf          # EC2 instance configuration
│       ├── variables.tf     # EC2 module variables
│       ├── outputs.tf       # EC2 module outputs
│       └── user_data.sh     # EC2 user data script
├── environments/
│   ├── staging.tfvars       # Staging environment variables
│   └── production.tfvars    # Production environment variables
├── main-modular.tf          # Main Terraform configuration
└── variables.tf             # Root variables
```

### Module Benefits

1. **Reusability**: Modules can be reused across different environments
2. **Maintainability**: Changes to infrastructure components are isolated
3. **Versioning**: Modules can be versioned independently
4. **Testing**: Individual modules can be tested in isolation
5. **Documentation**: Each module has clear inputs and outputs

## Modules

### VPC Module (`modules/vpc/`)

**Purpose**: Manages networking infrastructure including VPC, subnets, internet gateway, and route tables.

**Key Features**:
- Configurable CIDR blocks
- Public subnet with auto-assign public IPs
- Internet gateway for external connectivity
- Route table with default route to internet gateway

**Variables**:
- `vpc_cidr_block`: VPC CIDR block
- `public_subnet_cidr`: Public subnet CIDR block
- `availability_zone`: AWS availability zone
- `environment`: Environment name for tagging
- `common_tags`: Common tags for all resources

**Outputs**:
- `vpc_id`: VPC ID
- `public_subnet_id`: Public subnet ID
- `internet_gateway_id`: Internet gateway ID

### Security Groups Module (`modules/security-groups/`)

**Purpose**: Manages security group rules for different types of access.

**Key Features**:
- Configurable ingress rules for SSH, HTTP, HTTPS
- Flask microservices ports (5001-5003)
- Frontend port (8080)
- Optional database port exposure
- All outbound traffic allowed

**Variables**:
- `vpc_id`: VPC ID for security group
- `allowed_ssh_cidr_blocks`: CIDR blocks for SSH access
- `allowed_http_cidr_blocks`: CIDR blocks for HTTP/HTTPS access
- `expose_database_ports`: Whether to expose database ports
- `environment`: Environment name for tagging

**Outputs**:
- `security_group_id`: Security group ID
- `security_group_name`: Security group name

### EC2 Module (`modules/ec2/`)

**Purpose**: Manages EC2 instance with comprehensive user data setup.

**Key Features**:
- Automatic Ubuntu 22.04 AMI selection
- Configurable instance type and storage
- Comprehensive user data script
- Optional Elastic IP allocation
- SSH key and password configuration

**Variables**:
- `instance_type`: EC2 instance type
- `subnet_id`: Subnet ID for instance placement
- `security_group_ids`: Security group IDs to attach
- `root_volume_size`: Root volume size in GB
- `encrypt_volumes`: Whether to encrypt volumes
- `ssh_public_key`: SSH public key for access
- `instance_password`: Password for ubuntu user

**Outputs**:
- `instance_id`: EC2 instance ID
- `instance_public_ip`: Public IP address
- `instance_private_ip`: Private IP address
- `ssh_command`: SSH command to connect

## Environment Configuration

### Staging Environment (`environments/staging.tfvars`)

```hcl
environment = "staging"
vpc_cidr_block = "10.1.0.0/16"
public_subnet_cidr = "10.1.1.0/24"
instance_type = "t3.micro"
expose_database_ports = true
allocate_eip = false
```

### Production Environment (`environments/production.tfvars`)

```hcl
environment = "production"
vpc_cidr_block = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
instance_type = "t3.small"
expose_database_ports = false
allocate_eip = true
encrypt_volumes = true
```

## Deployment Methods

### Method 1: Automated GitHub Actions

1. **Push to environment branch**:
   ```bash
   git checkout -b staging
   git push origin staging
   ```

2. **Monitor deployment**:
   - Check GitHub Actions: `.github/workflows/modular-deploy.yml`
   - Workflow automatically detects environment from branch name
   - Builds and pushes Docker images with environment-specific tags
   - Deploys infrastructure using modular Terraform
   - Deploys application using Ansible

### Method 2: Manual Deployment Script

```bash
# Deploy to staging
./deploy-modular.sh staging

# Deploy to production
./deploy-modular.sh production
```

### Method 3: Direct Terraform Commands

```bash
cd infra

# Initialize Terraform
terraform init

# Plan deployment for staging
terraform plan -var-file="environments/staging.tfvars" -out=staging.plan

# Apply staging deployment
terraform apply staging.plan

# Plan deployment for production
terraform plan -var-file="environments/production.tfvars" -out=production.plan

# Apply production deployment
terraform apply production.plan
```

## Security Features

### Staging Environment
- Open access for development and testing
- Database ports exposed for debugging
- No volume encryption
- No Elastic IP (uses dynamic IP)

### Production Environment
- Restricted database access (VPC only)
- Volume encryption enabled
- Elastic IP for stable addressing
- Fail2ban for SSH protection
- Comprehensive monitoring and alerting
- Log rotation and retention policies

## Monitoring and Maintenance

### Production Monitoring
- Automated health checks every 5 minutes
- Resource usage monitoring (CPU, memory, disk)
- Database connectivity checks
- Email alerts for service failures
- Log rotation and retention

### Maintenance Tasks
- Regular security updates
- Docker image updates via Watchtower
- Database backups (configured but not implemented)
- Log analysis and cleanup

## Best Practices

### Module Design
1. **Single Responsibility**: Each module has one clear purpose
2. **Input Validation**: Variables have proper validation and defaults
3. **Output Documentation**: All outputs are documented with descriptions
4. **Version Constraints**: Use version constraints for providers and modules

### Environment Management
1. **Separate State Files**: Consider using separate state files for different environments
2. **Remote Backend**: Use remote backend (S3, Terraform Cloud) for production
3. **State Locking**: Enable state locking to prevent concurrent modifications
4. **Backup Strategy**: Implement state file backup strategy

### Security
1. **Principle of Least Privilege**: Grant minimum required permissions
2. **Network Segmentation**: Use separate VPCs for different environments
3. **Secret Management**: Use AWS Secrets Manager or similar for sensitive data
4. **Regular Audits**: Regularly audit security group rules and IAM policies

## Troubleshooting

### Common Issues

1. **Module Not Found**:
   ```bash
   terraform init  # Re-initialize to download modules
   ```

2. **Variable Validation Errors**:
   - Check variable types and constraints
   - Ensure all required variables are provided

3. **State Conflicts**:
   ```bash
   terraform refresh  # Refresh state
   terraform plan     # Check for drift
   ```

4. **Permission Issues**:
   - Verify AWS credentials and permissions
   - Check security group rules

### Useful Commands

```bash
# Validate Terraform configuration
terraform validate

# Format Terraform files
terraform fmt

# Show current state
terraform show

# List resources
terraform state list

# Import existing resources
terraform import module.ec2.aws_instance.main i-1234567890abcdef0
```

## Migration from Monolithic to Modular

### Step 1: Backup Current State
```bash
cp terraform.tfstate terraform.tfstate.backup
```

### Step 2: Create New Configuration
- Copy existing values to new variable files
- Update any environment-specific configurations

### Step 3: Plan Migration
```bash
terraform plan -var-file="environments/staging.tfvars"
```

### Step 4: Apply Migration
```bash
terraform apply -var-file="environments/staging.tfvars"
```

## Future Enhancements

1. **Multi-AZ Support**: Add support for multiple availability zones
2. **Auto Scaling**: Implement auto scaling groups for high availability
3. **Load Balancer**: Add application load balancer for traffic distribution
4. **RDS Integration**: Replace containerized databases with managed RDS
5. **CDN Integration**: Add CloudFront for static content delivery
6. **Monitoring Stack**: Integrate with CloudWatch, Prometheus, or Grafana

## Support

For issues with the modular Terraform setup:
1. Check this documentation
2. Review module documentation and examples
3. Validate Terraform configuration
4. Check AWS CloudTrail for API errors
5. Contact DevOps team 