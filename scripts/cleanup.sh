#!/bin/bash

# GitOps Infrastructure Cleanup Script
set -e

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

# Confirmation prompt
confirm_cleanup() {
    echo
    print_warning "This will destroy all GitOps infrastructure including:"
    echo "  - EKS cluster"
    echo "  - VPC and subnets"
    echo "  - ECR repositories"
    echo "  - All Kubernetes resources"
    echo
    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
}

# Cleanup ArgoCD applications
cleanup_argocd() {
    local environment=${1:-staging}
    
    print_status "Cleaning up ArgoCD applications..."

    # Configure kubectl
    aws eks update-kubeconfig \
        --region ap-southeast-1 \
        --name "${environment}-cluster"

    # Delete ArgoCD applications
    kubectl delete application --all -n argocd --ignore-not-found=true

    # Wait for applications to be deleted
    print_status "Waiting for applications to be deleted..."
    sleep 30

    # Delete ArgoCD
    helm uninstall argocd -n argocd --ignore-not-found=true
    kubectl delete namespace argocd --ignore-not-found=true

    print_status "ArgoCD cleanup completed"
}

# Cleanup monitoring
cleanup_monitoring() {
    print_status "Cleaning up monitoring..."

    # Uninstall Prometheus
    helm uninstall prometheus -n monitoring --ignore-not-found=true
    kubectl delete namespace monitoring --ignore-not-found=true

    # Uninstall External Secrets
    helm uninstall external-secrets -n external-secrets --ignore-not-found=true
    kubectl delete namespace external-secrets --ignore-not-found=true

    print_status "Monitoring cleanup completed"
}

# Cleanup infrastructure with Terraform
cleanup_infrastructure() {
    local environment=${1:-staging}
    
    print_status "Cleaning up infrastructure for environment: $environment"

    cd terraform

    # Initialize Terraform
    terraform init \
        -backend-config="bucket=gitops-learning-terraform-state-1753768527" \
        -backend-config="key=$environment/terraform.tfstate" \
        -backend-config="region=ap-southeast-1" \
        -backend-config="dynamodb_table=terraform-state-lock-new" \
        -backend-config="encrypt=true"

    # Destroy infrastructure
    print_status "Destroying infrastructure..."
    terraform destroy -var-file="environments/$environment.tfvars" -auto-approve

    cd ..

    print_status "Infrastructure cleanup completed"
}

# Cleanup local files
cleanup_local_files() {
    print_status "Cleaning up local files..."

    # Remove .env file
    rm -f .env

    # Remove Terraform files
    rm -f terraform/*.plan
    rm -f terraform/.terraform.lock.hcl

    print_status "Local files cleanup completed"
}

# Main function
main() {
    local environment=${1:-staging}
    
    print_status "Starting GitOps infrastructure cleanup for environment: $environment"

    # Confirmation
    confirm_cleanup

    # Check AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS credentials not configured or invalid"
        exit 1
    fi

    # Cleanup ArgoCD applications
    cleanup_argocd "$environment"

    # Cleanup monitoring
    cleanup_monitoring

    # Cleanup infrastructure
    cleanup_infrastructure "$environment"

    # Cleanup local files
    cleanup_local_files

    print_status "🎉 GitOps infrastructure cleanup completed successfully!"
}

# Script execution
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [environment]"
    echo "  environment: staging (default) or production"
    echo "  This will destroy all GitOps infrastructure"
    exit 0
fi

main "$@" 