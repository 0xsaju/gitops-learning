#!/bin/bash

# Terraform State Management Script
# This script helps manage and verify Terraform state configuration

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

# Configuration
BUCKET_NAME="gitops-learning-terraform-state-1753704333"
REGION="ap-southeast-1"
DYNAMODB_TABLE="terraform-state-lock"

print_header "Terraform State Management"

# Check if AWS CLI is configured
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured"
    exit 1
fi

print_status "AWS credentials configured"

# Function to check S3 bucket
check_s3_bucket() {
    print_header "Checking S3 Bucket"
    
    if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
        print_status "✅ S3 bucket exists: $BUCKET_NAME"
        
        # List state files
        echo ""
        print_status "State files in bucket:"
        aws s3 ls "s3://$BUCKET_NAME/" --recursive || echo "No files found"
        
    else
        print_error "❌ S3 bucket does not exist: $BUCKET_NAME"
        echo ""
        print_status "Creating S3 bucket..."
        aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$BUCKET_NAME" \
            --versioning-configuration Status=Enabled
            
        # Apply bucket policy
        if [ -f "s3-bucket-policy.json" ]; then
            aws s3api put-bucket-policy \
                --bucket "$BUCKET_NAME" \
                --policy file://s3-bucket-policy.json
            print_status "✅ Applied bucket policy"
        fi
        
        print_status "✅ S3 bucket created and configured"
    fi
}

# Function to check DynamoDB table
check_dynamodb_table() {
    print_header "Checking DynamoDB Table"
    
    if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" &> /dev/null; then
        print_status "✅ DynamoDB table exists: $DYNAMODB_TABLE"
    else
        print_error "❌ DynamoDB table does not exist: $DYNAMODB_TABLE"
        echo ""
        print_status "Creating DynamoDB table..."
        
        aws dynamodb create-table \
            --table-name "$DYNAMODB_TABLE" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "$REGION"
            
        print_status "✅ DynamoDB table created"
    fi
}

# Function to initialize Terraform for environment
init_terraform() {
    local environment=$1
    
    print_header "Initializing Terraform for $environment"
    
    cd infra
    
    # Remove any existing .terraform directory
    rm -rf .terraform
    
    # Initialize with environment-specific state file
    terraform init \
        -backend-config="bucket=$BUCKET_NAME" \
        -backend-config="key=$environment/terraform.tfstate" \
        -backend-config="region=$REGION" \
        -backend-config="dynamodb_table=$DYNAMODB_TABLE" \
        -backend-config="encrypt=true"
        
    print_status "✅ Terraform initialized for $environment"
    
    # Show current state
    echo ""
    print_status "Current state for $environment:"
    terraform state list || echo "No resources in state"
    
    cd ..
}

# Function to clean up state files
cleanup_state() {
    local environment=$1
    
    print_header "Cleaning up state for $environment"
    
    if aws s3 ls "s3://$BUCKET_NAME/$environment/terraform.tfstate" &> /dev/null; then
        print_warning "Removing state file for $environment..."
        aws s3 rm "s3://$BUCKET_NAME/$environment/terraform.tfstate"
        print_status "✅ State file removed for $environment"
    else
        print_status "No state file found for $environment"
    fi
}

# Main menu
show_menu() {
    echo ""
    print_header "Available Actions"
    echo "1. Check S3 bucket and DynamoDB table"
    echo "2. Initialize Terraform for staging"
    echo "3. Initialize Terraform for production"
    echo "4. Clean up staging state"
    echo "5. Clean up production state"
    echo "6. Show all state files"
    echo "7. Exit"
    echo ""
    read -p "Choose an option (1-7): " choice
}

# Main execution
case "${1:-}" in
    "check")
        check_s3_bucket
        check_dynamodb_table
        ;;
    "init-staging")
        check_s3_bucket
        check_dynamodb_table
        init_terraform "staging"
        ;;
    "init-production")
        check_s3_bucket
        check_dynamodb_table
        init_terraform "production"
        ;;
    "cleanup-staging")
        cleanup_state "staging"
        ;;
    "cleanup-production")
        cleanup_state "production"
        ;;
    "list")
        print_header "All State Files"
        aws s3 ls "s3://$BUCKET_NAME/" --recursive || echo "No files found"
        ;;
    *)
        # Interactive mode
        while true; do
            show_menu
            case $choice in
                1)
                    check_s3_bucket
                    check_dynamodb_table
                    ;;
                2)
                    check_s3_bucket
                    check_dynamodb_table
                    init_terraform "staging"
                    ;;
                3)
                    check_s3_bucket
                    check_dynamodb_table
                    init_terraform "production"
                    ;;
                4)
                    cleanup_state "staging"
                    ;;
                5)
                    cleanup_state "production"
                    ;;
                6)
                    print_header "All State Files"
                    aws s3 ls "s3://$BUCKET_NAME/" --recursive || echo "No files found"
                    ;;
                7)
                    print_status "Exiting..."
                    exit 0
                    ;;
                *)
                    print_error "Invalid option"
                    ;;
            esac
        done
        ;;
esac 