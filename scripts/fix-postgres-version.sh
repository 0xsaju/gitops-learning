#!/bin/bash

# Fix PostgreSQL Version Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check available PostgreSQL versions
check_postgres_versions() {
    print_header "Checking Available PostgreSQL Versions"
    
    print_status "Fetching available PostgreSQL versions for ap-southeast-1..."
    aws rds describe-db-engine-versions \
        --engine postgres \
        --region ap-southeast-1 \
        --query 'DBEngineVersions[].EngineVersion' \
        --output table
}

# Fix Terraform configuration
fix_terraform_config() {
    print_header "Fixing Terraform Configuration"
    
    # Get the latest PostgreSQL 15.x version
    LATEST_PG15=$(aws rds describe-db-engine-versions \
        --engine postgres \
        --region ap-southeast-1 \
        --query 'DBEngineVersions[?starts_with(EngineVersion, `15.`)].EngineVersion' \
        --output text | tr '\t' '\n' | sort -V | tail -1)
    
    print_status "Latest PostgreSQL 15.x version: $LATEST_PG15"
    
    # Update the Terraform file
    if [ -n "$LATEST_PG15" ]; then
        sed -i.bak "s/engine_version = \"15.4\"/engine_version = \"$LATEST_PG15\"/" terraform/main.tf
        print_status "Updated engine_version to $LATEST_PG15 in terraform/main.tf"
    else
        print_warning "Could not find PostgreSQL 15.x version, using 14.x"
        LATEST_PG14=$(aws rds describe-db-engine-versions \
            --engine postgres \
            --region ap-southeast-1 \
            --query 'DBEngineVersions[?starts_with(EngineVersion, `14.`)].EngineVersion' \
            --output text | tr '\t' '\n' | sort -V | tail -1)
        
        sed -i.bak "s/engine_version = \"15.4\"/engine_version = \"$LATEST_PG14\"/" terraform/main.tf
        print_status "Updated engine_version to $LATEST_PG14 in terraform/main.tf"
    fi
}

# Apply Terraform changes
apply_terraform_fix() {
    print_header "Applying Terraform Fix"
    
    cd terraform
    
    # Re-initialize if needed
    print_status "Terraform plan with fixed version..."
    terraform plan -var-file="environments/staging.tfvars"
    
    print_status "Applying Terraform changes..."
    terraform apply -var-file="environments/staging.tfvars" -auto-approve
    
    cd ..
}

# Main function
main() {
    local action=${1:-fix}
    
    case $action in
        "check")
            check_postgres_versions
            ;;
        "fix")
            check_postgres_versions
            fix_terraform_config
            apply_terraform_fix
            ;;
        "apply-only")
            apply_terraform_fix
            ;;
        *)
            echo "Usage: $0 [action]"
            echo "  Actions:"
            echo "    check      - Check available PostgreSQL versions"
            echo "    fix        - Fix and apply Terraform configuration (default)"
            echo "    apply-only - Apply Terraform without checking versions"
            exit 1
            ;;
    esac
}

main "$@"
