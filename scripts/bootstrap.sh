#!/bin/bash

# GitOps Infrastructure Bootstrap Script
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

# Check if required tools are installed
check_requirements() {
    print_status "Checking requirements..."

    local missing_tools=()

    # Check for required tools
    command -v terraform >/dev/null 2>&1 || missing_tools+=("terraform")
    command -v aws >/dev/null 2>&1 || missing_tools+=("aws")
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    command -v helm >/dev/null 2>&1 || missing_tools+=("helm")
    command -v argocd >/dev/null 2>&1 || missing_tools+=("argocd")

    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_status "Please install the missing tools and try again."
        exit 1
    fi

    print_status "All requirements are met"
}

# Check AWS credentials
check_aws_credentials() {
    print_status "Checking AWS credentials..."

    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS credentials not configured or invalid"
        print_status "Please run 'aws configure' or set up your credentials"
        exit 1
    fi

    print_status "AWS credentials are valid"
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    local environment=${1:-staging}
    
    print_status "Deploying infrastructure for environment: $environment"

    cd terraform

    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init \
        -backend-config="bucket=gitops-learning-terraform-state-1753768527" \
        -backend-config="key=$environment/terraform.tfstate" \
        -backend-config="region=ap-southeast-1" \
        -backend-config="dynamodb_table=terraform-state-lock-new" \
        -backend-config="encrypt=true"

    # Plan the deployment
    print_status "Planning Terraform deployment..."
    terraform plan -var-file="environments/$environment.tfvars" -out="$environment.plan"

    # Apply the plan
    print_status "Applying Terraform plan..."
    terraform apply "$environment.plan"

    # Get outputs
    print_status "Getting Terraform outputs..."
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "${environment}-cluster")
    CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint 2>/dev/null || echo "")
    VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")

    cd ..

    # Save outputs for later use
    echo "CLUSTER_NAME=$CLUSTER_NAME" > .env
    echo "CLUSTER_ENDPOINT=$CLUSTER_ENDPOINT" >> .env
    echo "VPC_ID=$VPC_ID" >> .env
    echo "ENVIRONMENT=$environment" >> .env

    print_status "Infrastructure deployed successfully"
}

# Configure kubectl
configure_kubectl() {
    local environment=${1:-staging}
    
    print_status "Configuring kubectl for EKS cluster..."

    # Update kubeconfig
    aws eks update-kubeconfig \
        --region ap-southeast-1 \
        --name "${environment}-cluster"

    # Test connection
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Failed to connect to EKS cluster"
        exit 1
    fi

    print_status "kubectl configured successfully"
}

# Install ArgoCD
install_argocd() {
    local environment=${1:-staging}
    
    print_status "Installing ArgoCD..."

    # Add ArgoCD Helm repository
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update

    # Create namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

    # Install ArgoCD
    helm upgrade --install argocd argo/argocd \
        --namespace argocd \
        --values argocd/values.yaml \
        --set server.ingress.hosts[0]="argocd.${environment}.example.com" \
        --wait

    # Wait for ArgoCD to be ready
    print_status "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

    # Get admin password
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "ARGOCD_PASSWORD=$ARGOCD_PASSWORD" >> .env

    print_status "ArgoCD installed successfully"
    print_status "ArgoCD URL: https://argocd.${environment}.example.com"
    print_status "Username: admin"
    print_status "Password: $ARGOCD_PASSWORD"
}

# Apply App-of-Apps
apply_app_of_apps() {
    print_status "Applying App-of-Apps configuration..."

    kubectl apply -f argocd/app-of-apps.yaml

    print_status "App-of-Apps applied successfully"
}

# Install External Secrets Operator
install_external_secrets() {
    print_status "Installing External Secrets Operator..."

    # Add Helm repository
    helm repo add external-secrets https://charts.external-secrets.io
    helm repo update

    # Install External Secrets Operator
    helm upgrade --install external-secrets external-secrets/external-secrets \
        --namespace external-secrets \
        --create-namespace \
        --wait

    print_status "External Secrets Operator installed successfully"
}

# Setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring..."

    # Install Prometheus Operator
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set grafana.enabled=true \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        --wait

    print_status "Monitoring setup completed"
}

# Main function
main() {
    local environment=${1:-staging}
    
    print_status "Starting GitOps infrastructure bootstrap for environment: $environment"

    # Check requirements
    check_requirements
    check_aws_credentials

    # Deploy infrastructure
    deploy_infrastructure "$environment"

    # Configure kubectl
    configure_kubectl "$environment"

    # Install ArgoCD
    install_argocd "$environment"

    # Install External Secrets Operator
    install_external_secrets

    # Setup monitoring
    setup_monitoring

    # Apply App-of-Apps
    apply_app_of_apps

    print_status "🎉 GitOps infrastructure bootstrap completed successfully!"
    print_status "Next steps:"
    print_status "1. Update your DNS to point to the ALB endpoint"
    print_status "2. Push to staging branch to trigger deployment"
    print_status "3. Access ArgoCD at: https://argocd.${environment}.example.com"
}

# Script execution
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [environment]"
    echo "  environment: staging (default) or production"
    exit 0
fi

main "$@" 