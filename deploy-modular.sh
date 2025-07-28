#!/bin/bash

# Modular Terraform Deployment Script
# Usage: ./deploy-modular.sh [staging|production]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if environment is provided
if [ $# -eq 0 ]; then
    print_error "Please specify environment: staging or production"
    echo "Usage: $0 [staging|production]"
    exit 1
fi

ENVIRONMENT=$1

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    print_error "Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

print_header "Modular Terraform Deployment"
print_status "Environment: $ENVIRONMENT"

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
    
    DOCKER_TAG=$ENVIRONMENT
    
    # Build and push User Service
    print_status "Building User Service..."
    docker build -t 0xsaju/flask-user-service:$DOCKER_TAG ./user-service
    docker push 0xsaju/flask-user-service:$DOCKER_TAG
    
    # Build and push Product Service
    print_status "Building Product Service..."
    docker build -t 0xsaju/flask-product-service:$DOCKER_TAG ./product-service
    docker push 0xsaju/flask-product-service:$DOCKER_TAG
    
    # Build and push Order Service
    print_status "Building Order Service..."
    docker build -t 0xsaju/flask-order-service:$DOCKER_TAG ./order-service
    docker push 0xsaju/flask-order-service:$DOCKER_TAG
    
    # Build and push Frontend
    print_status "Building Frontend..."
    docker build -t 0xsaju/flask-frontend:$DOCKER_TAG ./frontend
    docker push 0xsaju/flask-frontend:$DOCKER_TAG
    
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
    print_status "Planning Terraform deployment for $ENVIRONMENT..."
    terraform plan -var-file="environments/$ENVIRONMENT.tfvars" -out="$ENVIRONMENT.plan"
    
    # Apply Terraform deployment
    print_status "Applying Terraform deployment..."
    terraform apply "$ENVIRONMENT.plan"
    
    # Get server IP
    SERVER_IP=$(terraform output -raw instance_public_ip)
    print_status "$ENVIRONMENT server IP: $SERVER_IP"
    
    cd ..
    
    echo $SERVER_IP > ".${ENVIRONMENT}_ip"
}

# Deploy application with Ansible
deploy_application() {
    print_status "Deploying application with Ansible..."
    
    SERVER_IP=$(cat ".${ENVIRONMENT}_ip")
    
    cd ansible
    
    # Wait for server to be ready
    print_status "Waiting for server to be ready..."
    sleep 30
    
    # Deploy with Ansible
    print_status "Running Ansible playbook for $ENVIRONMENT..."
    ansible-playbook -i "${ENVIRONMENT}-inventory" "${ENVIRONMENT}-playbook.yml" --extra-vars "staging_ip=$SERVER_IP"
    
    cd ..
}

# Health check
health_check() {
    print_status "Performing health check..."
    
    SERVER_IP=$(cat ".${ENVIRONMENT}_ip")
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 60
    
    # Test services
    print_status "Testing Frontend..."
    curl -f http://$SERVER_IP:8080 || { print_error "Frontend health check failed"; exit 1; }
    
    print_status "Testing User Service..."
    curl -f http://$SERVER_IP:5001/api/users || { print_error "User Service health check failed"; exit 1; }
    
    print_status "Testing Product Service..."
    curl -f http://$SERVER_IP:5002/api/products || { print_error "Product Service health check failed"; exit 1; }
    
    print_status "Testing Order Service..."
    curl -f http://$SERVER_IP:5003/api/orders || { print_error "Order Service health check failed"; exit 1; }
    
    print_status "All health checks passed!"
}

# Display deployment info
display_info() {
    SERVER_IP=$(cat ".${ENVIRONMENT}_ip")
    
    echo ""
    print_header "$ENVIRONMENT Deployment Completed Successfully!"
    echo ""
    echo "📋 Deployment Information:"
    echo "   Environment:   $ENVIRONMENT"
    echo "   Server IP:     $SERVER_IP"
    echo "   Frontend:      http://$SERVER_IP:8080"
    echo "   User Service:  http://$SERVER_IP:5001"
    echo "   Product Service: http://$SERVER_IP:5002"
    echo "   Order Service: http://$SERVER_IP:5003"
    echo ""
    echo "🔧 Management:"
    echo "   SSH: ssh ubuntu@$SERVER_IP"
    echo "   Password: Ubuntu2024!"
    echo ""
    echo "📁 Terraform State:"
    echo "   State file: infra/terraform.tfstate"
    echo "   Backend: Local (consider using remote backend for production)"
    echo ""
}

# Cleanup function
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -f ".${ENVIRONMENT}_ip"
}

# Main deployment process
main() {
    print_header "Starting $ENVIRONMENT Deployment"
    
    check_prerequisites
    build_and_push_images
    deploy_infrastructure
    deploy_application
    health_check
    display_info
    cleanup
    
    print_status "$ENVIRONMENT deployment completed successfully!"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Run main function
main "$@" 