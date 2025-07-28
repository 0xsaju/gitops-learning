# Staging Deployment Guide

## Overview

This document describes the staging deployment process for the Flask microservices application. The staging environment is a separate AWS infrastructure that mirrors the production setup for testing and validation.

## Architecture

### Staging Infrastructure
- **AWS Region**: ap-southeast-1
- **Instance Type**: t3.micro
- **OS**: Ubuntu 22.04 LTS
- **VPC**: 10.1.0.0/16 (separate from production)
- **Subnet**: 10.1.1.0/24

### Services
- **Frontend**: Flask web application (Port 8080)
- **User Service**: User management API (Port 5001)
- **Product Service**: Product catalog API (Port 5002)
- **Order Service**: Order management API (Port 5003)
- **Databases**: MySQL 8 (Ports 32000-32002)
- **Watchtower**: Auto-update service

## Prerequisites

### Required Tools
- Terraform >= 1.5.0
- Ansible >= 2.9
- Docker >= 20.10
- AWS CLI configured
- Docker Hub account

### Required Secrets
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

## Deployment Methods

### Method 1: Automated GitHub Actions (Recommended)

1. **Push to staging branch**:
   ```bash
   git checkout -b staging
   git push origin staging
   ```

2. **Monitor deployment**:
   - Check GitHub Actions: `.github/workflows/staging-deploy.yml`
   - Wait for all jobs to complete
   - Verify health checks pass

### Method 2: Manual Deployment

1. **Run deployment script**:
   ```bash
   ./deploy-staging.sh
   ```

2. **Or deploy step by step**:
   ```bash
   # Build and push images
   docker build -t 0xsaju/flask-user-service:staging ./user-service
   docker push 0xsaju/flask-user-service:staging
   # ... repeat for other services
   
   # Deploy infrastructure
   cd infra
   terraform init
   terraform plan -var-file=staging.tfvars
   terraform apply
   
   # Deploy application
   cd ../ansible
   ansible-playbook -i staging-inventory staging-playbook.yml
   ```

## Configuration Files

### Terraform
- `infra/staging.tf` - Staging infrastructure definition
- `infra/staging.tfvars` - Staging variables

### Ansible
- `ansible/staging-playbook.yml` - Staging deployment playbook
- `ansible/staging-inventory` - Staging server inventory
- `ansible/files/staging-docker-compose.yml.j2` - Docker Compose template
- `ansible/files/staging.env.j2` - Environment variables template

### GitHub Actions
- `.github/workflows/staging-deploy.yml` - Automated deployment workflow

## Database Configuration

### Staging Databases
- **User Database**: `user_management` (Port 32000)
- **Product Database**: `product_catalog` (Port 32001)
- **Order Database**: `order_management` (Port 32002)

### Credentials
- **Root Password**: `R00tD$bP@ssW0rd`
- **Application User**: `dbuser`
- **Application Password**: `testpass123`

## Access Information

### SSH Access
```bash
ssh ubuntu@<STAGING_IP>
# Password: Ubuntu2024!
```

### Service URLs
- **Frontend**: http://<STAGING_IP>:8080
- **User API**: http://<STAGING_IP>:5001
- **Product API**: http://<STAGING_IP>:5002
- **Order API**: http://<STAGING_IP>:5003

### Database Access
```bash
# User Database
mysql -h <STAGING_IP> -P 32000 -u dbuser -ptestpass123 user_management

# Product Database
mysql -h <STAGING_IP> -P 32001 -u dbuser -ptestpass123 product_catalog

# Order Database
mysql -h <STAGING_IP> -P 32002 -u dbuser -ptestpass123 order_management
```

## Health Checks

### Manual Health Check
```bash
# Test all services
curl -f http://<STAGING_IP>:8080
curl -f http://<STAGING_IP>:5001/api/users
curl -f http://<STAGING_IP>:5002/api/products
curl -f http://<STAGING_IP>:5003/api/orders
```

### Automated Health Check
The deployment process includes automated health checks that verify all services are responding correctly.

## Troubleshooting

### Common Issues

1. **Docker images not found**:
   - Ensure images are built and pushed to Docker Hub
   - Check Docker Hub credentials

2. **Database connection issues**:
   - Verify database containers are running
   - Check database credentials in configuration

3. **Service not responding**:
   - Check container logs: `docker logs <container_name>`
   - Verify ports are open in security group
   - Check service dependencies

### Useful Commands

```bash
# Check container status
docker ps -a

# View container logs
docker logs staging_frontend_app

# Restart services
docker-compose -f /home/ubuntu/staging-app/docker-compose.yml restart

# Check database connectivity
docker exec -it staging_user_dbase mysql -u root -pR00tD$bP@ssW0rd -e "SHOW DATABASES;"
```

## Cleanup

### Destroy Staging Environment
```bash
cd infra
terraform destroy -var-file=staging.tfvars
```

### Remove Docker Images
```bash
docker rmi 0xsaju/flask-user-service:staging
docker rmi 0xsaju/flask-product-service:staging
docker rmi 0xsaju/flask-order-service:staging
docker rmi 0xsaju/flask-frontend:staging
```

## Security Considerations

1. **Network Security**: Staging environment uses separate VPC
2. **Database Security**: Separate databases with staging-specific credentials
3. **Access Control**: Limited access to staging environment
4. **Secrets Management**: Use environment variables for sensitive data

## Monitoring

### Logs
- Application logs: `docker logs <container_name>`
- System logs: `/var/log/syslog`
- Docker logs: `journalctl -u docker`

### Metrics
- Container resource usage: `docker stats`
- System resource usage: `htop`, `df -h`

## Support

For issues with staging deployment:
1. Check this documentation
2. Review container logs
3. Verify infrastructure status
4. Contact DevOps team 