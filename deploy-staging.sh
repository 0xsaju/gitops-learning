#!/bin/bash

# Staging Deployment Script
# Usage: ./deploy-staging.sh

set -e

echo "🚀 Starting Staging Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    print_status "All prerequisites are satisfied."
}

# Build and push Docker images
build_and_push_images() {
    print_status "Building and pushing Docker images..."
    
    # Build and push User Service
    print_status "Building User Service..."
    docker build -t 0xsaju/flask-user-service:staging ./user-service
    docker push 0xsaju/flask-user-service:staging
    
    # Build and push Product Service
    print_status "Building Product Service..."
    docker build -t 0xsaju/flask-product-service:staging ./product-service
    docker push 0xsaju/flask-product-service:staging
    
    # Build and push Order Service
    print_status "Building Order Service..."
    docker build -t 0xsaju/flask-order-service:staging ./order-service
    docker push 0xsaju/flask-order-service:staging
    
    # Build and push Frontend
    print_status "Building Frontend..."
    docker build -t 0xsaju/flask-frontend:staging ./frontend
    docker push 0xsaju/flask-frontend:staging
    
    print_status "All Docker images built and pushed successfully."
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd infra
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan Terraform deployment
    print_status "Planning Terraform deployment..."
    terraform plan -var-file=staging.tfvars -out=staging.plan
    
    # Apply Terraform deployment
    print_status "Applying Terraform deployment..."
    terraform apply staging.plan
    
    # Get staging server IP
    STAGING_IP=$(terraform output -raw staging_vm_public_ip)
    print_status "Staging server IP: $STAGING_IP"
    
    cd ..
    
    echo $STAGING_IP > .staging_ip
}

# Deploy application with Ansible
deploy_application() {
    print_status "Deploying application with Ansible..."
    
    STAGING_IP=$(cat .staging_ip)
    
    cd ansible
    
    # Wait for server to be ready
    print_status "Waiting for server to be ready..."
    sleep 30
    
    # Deploy with Ansible
    print_status "Running Ansible playbook..."
    ansible-playbook -i staging-inventory staging-playbook.yml --extra-vars "staging_ip=$STAGING_IP"
    
    cd ..
}

# Health check
health_check() {
    print_status "Performing health check..."
    
    STAGING_IP=$(cat .staging_ip)
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 60
    
    # Test services
    print_status "Testing Frontend..."
    curl -f http://$STAGING_IP:8080 || { print_error "Frontend health check failed"; exit 1; }
    
    print_status "Testing User Service..."
    curl -f http://$STAGING_IP:5001/api/users || { print_error "User Service health check failed"; exit 1; }
    
    print_status "Testing Product Service..."
    curl -f http://$STAGING_IP:5002/api/products || { print_error "Product Service health check failed"; exit 1; }
    
    print_status "Testing Order Service..."
    curl -f http://$STAGING_IP:5003/api/orders || { print_error "Order Service health check failed"; exit 1; }
    
    print_status "All health checks passed!"
}

# Display deployment info
display_info() {
    STAGING_IP=$(cat .staging_ip)
    
    echo ""
    echo "🎉 Staging deployment completed successfully!"
    echo ""
    echo "📋 Deployment Information:"
    echo "   Frontend:     http://$STAGING_IP:8080"
    echo "   User Service: http://$STAGING_IP:5001"
    echo "   Product Service: http://$STAGING_IP:5002"
    echo "   Order Service: http://$STAGING_IP:5003"
    echo ""
    echo "🔧 Management:"
    echo "   SSH: ssh ubuntu@$STAGING_IP"
    echo "   Password: Ubuntu2024!"
    echo ""
}

# Main deployment process
main() {
    print_status "Starting staging deployment process..."
    
    check_prerequisites
    build_and_push_images
    deploy_infrastructure
    deploy_application
    health_check
    display_info
    
    print_status "Staging deployment completed successfully!"
}

# Run main function
main "$@" 