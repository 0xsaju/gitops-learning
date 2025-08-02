#!/bin/bash

# GitOps Setup Script
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

# Check if required tools are installed
check_requirements() {
    print_status "Checking requirements..."

    local missing_tools=()

    command -v terraform >/dev/null 2>&1 || missing_tools+=("terraform")
    command -v aws >/dev/null 2>&1 || missing_tools+=("aws")
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    command -v helm >/dev/null 2>&1 || missing_tools+=("helm")
    command -v gh >/dev/null 2>&1 || missing_tools+=("gh")

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

    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_status "AWS Account ID: $AWS_ACCOUNT_ID"
}

# Setup GitHub secrets
setup_github_secrets() {
    print_header "Setting up GitHub Secrets"

    # Check if GitHub CLI is authenticated
    if ! gh auth status >/dev/null 2>&1; then
        print_error "GitHub CLI not authenticated"
        print_status "Please run 'gh auth login' first"
        exit 1
    fi

    # Get current repository
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    print_status "Repository: $REPO"

    # Check existing secrets
    print_status "Checking existing secrets..."
    
    if gh secret list 2>/dev/null | grep -q "AWS_ACCESS_KEY_ID"; then
        print_status "✅ AWS_ACCESS_KEY_ID already exists"
    else
        print_warning "AWS_ACCESS_KEY_ID not found"
        read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
        echo "$AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID
        print_status "✅ AWS_ACCESS_KEY_ID set"
    fi

    if gh secret list 2>/dev/null | grep -q "AWS_SECRET_ACCESS_KEY"; then
        print_status "✅ AWS_SECRET_ACCESS_KEY already exists"
    else
        print_warning "AWS_SECRET_ACCESS_KEY not found"
        read -s -p "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
        echo
        echo "$AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY
        print_status "✅ AWS_SECRET_ACCESS_KEY set"
    fi

    if gh secret list 2>/dev/null | grep -q "DOCKERHUB_USERNAME"; then
        print_status "✅ DOCKERHUB_USERNAME already exists"
    else
        print_warning "DOCKERHUB_USERNAME not found"
        read -p "Enter your Docker Hub username: " DOCKERHUB_USERNAME
        echo "$DOCKERHUB_USERNAME" | gh secret set DOCKERHUB_USERNAME
        print_status "✅ DOCKERHUB_USERNAME set"
    fi

    if gh secret list 2>/dev/null | grep -q "DOCKERHUB_TOKEN"; then
        print_status "✅ DOCKERHUB_TOKEN already exists"
    else
        print_warning "DOCKERHUB_TOKEN not found"
        read -s -p "Enter your Docker Hub access token: " DOCKERHUB_TOKEN
        echo
        echo "$DOCKERHUB_TOKEN" | gh secret set DOCKERHUB_TOKEN
        print_status "✅ DOCKERHUB_TOKEN set"
    fi

    print_status "All GitHub secrets configured"
}

# Create AWS resources for Terraform backend
setup_aws_backend() {
    print_header "Setting up AWS Backend"

    # Create S3 bucket for Terraform state
    BUCKET_NAME="gitops-learning-terraform-state-1753768527"
    
    if aws s3 ls "s3://$BUCKET_NAME" >/dev/null 2>&1; then
        print_status "✅ S3 bucket $BUCKET_NAME already exists"
    else
        print_status "Creating S3 bucket for Terraform state..."
        aws s3 mb "s3://$BUCKET_NAME" --region ap-southeast-1
        aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
        aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
        print_status "✅ S3 bucket created and configured"
    fi

    # Create DynamoDB table for state locking
    TABLE_NAME="terraform-state-lock-new"
    
    if aws dynamodb describe-table --table-name "$TABLE_NAME" >/dev/null 2>&1; then
        print_status "✅ DynamoDB table $TABLE_NAME already exists"
    else
        print_status "Creating DynamoDB table for state locking..."
        aws dynamodb create-table \
            --table-name "$TABLE_NAME" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
            --region ap-southeast-1
        print_status "✅ DynamoDB table created"
    fi
}

# Create staging branch
setup_branches() {
    print_header "Setting up Git Branches"

    # Check if staging branch exists
    if git show-ref --verify --quiet refs/remotes/origin/staging; then
        print_status "✅ Staging branch already exists"
        git checkout staging
    else
        print_status "Creating staging branch..."
        git checkout -b staging
        git push -u origin staging
        print_status "✅ Staging branch created and pushed"
    fi

    # Check if production branch exists
    if git show-ref --verify --quiet refs/remotes/origin/production; then
        print_status "✅ Production branch already exists"
    else
        print_status "Creating production branch..."
        git checkout -b production
        git push -u origin production
        print_status "✅ Production branch created and pushed"
    fi

    # Switch back to main
    git checkout main
}

# Deploy infrastructure
deploy_infrastructure() {
    local environment=${1:-staging}
    
    print_header "Deploying Infrastructure for $environment"

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

# Install ArgoCD
install_argocd() {
    local environment=${1:-staging}
    
    print_header "Installing ArgoCD"

    # Configure kubectl
    print_status "Configuring kubectl..."
    aws eks update-kubeconfig \
        --region ap-southeast-1 \
        --name "${environment}-cluster"

    # Add ArgoCD Helm repository
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update

    # Create namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

    # Install ArgoCD
    print_status "Installing ArgoCD..."
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

    # Get ALB DNS
    print_status "Getting ALB DNS..."
    sleep 30  # Wait for ALB to be provisioned
    ARGOCD_ALB_DNS=$(kubectl get ingress argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    echo "ARGOCD_ALB_DNS=$ARGOCD_ALB_DNS" >> .env

    print_status "ArgoCD installed successfully"
    print_status "ArgoCD URL: https://$ARGOCD_ALB_DNS"
    print_status "Username: admin"
    print_status "Password: $ARGOCD_PASSWORD"
}

# Apply App-of-Apps
apply_app_of_apps() {
    print_header "Applying App-of-Apps"

    kubectl apply -f argocd/app-of-apps.yaml

    print_status "App-of-Apps applied successfully"
}

# Main function
main() {
    local environment=${1:-staging}
    
    print_header "GitOps Infrastructure Setup"
    print_status "Environment: $environment"

    # Check requirements
    check_requirements
    check_aws_credentials

    # Setup GitHub secrets
    setup_github_secrets

    # Setup AWS backend
    setup_aws_backend

    # Setup Git branches
    setup_branches

    # Deploy infrastructure
    deploy_infrastructure "$environment"

    # Install ArgoCD
    install_argocd "$environment"

    # Apply App-of-Apps
    apply_app_of_apps

    print_header "🎉 Setup Complete!"
    print_status "Next steps:"
    print_status "1. Push to staging branch to trigger deployment"
    print_status "2. Access ArgoCD at: https://argocd.${environment}.example.com"
    print_status "3. Monitor deployment in GitHub Actions"
    print_status ""
    print_status "To deploy applications:"
    print_status "git checkout staging"
    print_status "git push origin staging"
}

# Script execution
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [environment]"
    echo "  environment: staging (default) or production"
    echo ""
    echo "This script will:"
    echo "1. Check requirements"
    echo "2. Setup GitHub secrets"
    echo "3. Create AWS backend resources"
    echo "4. Setup Git branches"
    echo "5. Deploy infrastructure"
    echo "6. Install ArgoCD"
    echo "7. Apply App-of-Apps"
    exit 0
fi

main "$@" 