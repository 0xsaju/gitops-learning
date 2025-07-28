#!/bin/bash

# Local GitHub Secrets Test Script
# This script simulates the GitHub Actions workflow locally

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

print_header "Local GitHub Secrets Testing"

echo ""
echo "This script simulates the GitHub Actions workflow locally."
echo "It will test all the components that would be tested in the CI/CD pipeline."
echo ""

# Test 1: Check if required tools are installed
print_header "Testing Required Tools"

print_status "Checking Terraform..."
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo "unknown")
    print_status "✅ Terraform is installed (version: $TERRAFORM_VERSION)"
else
    print_error "❌ Terraform is not installed"
    exit 1
fi

print_status "Checking Ansible..."
if command -v ansible-playbook &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n1 | cut -d' ' -f2 2>/dev/null || echo "unknown")
    print_status "✅ Ansible is installed (version: $ANSIBLE_VERSION)"
else
    print_error "❌ Ansible is not installed"
    exit 1
fi

print_status "Checking Docker..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | sed 's/,//' 2>/dev/null || echo "unknown")
    print_status "✅ Docker is installed (version: $DOCKER_VERSION)"
else
    print_error "❌ Docker is not installed"
    exit 1
fi

print_status "Checking jq..."
if command -v jq &> /dev/null; then
    print_status "✅ jq is installed"
else
    print_warning "⚠️  jq is not installed (optional for JSON parsing)"
fi

# Test 2: Test Terraform Configuration
print_header "Testing Terraform Configuration"

cd infra

print_status "Validating Terraform configuration..."
if terraform validate; then
    print_status "✅ Terraform configuration is valid"
else
    print_error "❌ Terraform configuration validation failed"
    exit 1
fi

print_status "Testing staging plan..."
if terraform plan -var-file="environments/staging.tfvars" -detailed-exitcode > /dev/null 2>&1; then
    print_status "✅ Staging plan generated successfully"
else
    # Exit code 2 means plan would create resources (which is expected)
    if [ $? -eq 2 ]; then
        print_status "✅ Staging plan generated successfully (would create resources)"
    else
        print_error "❌ Staging plan failed"
        exit 1
    fi
fi

print_status "Testing production plan..."
if terraform plan -var-file="environments/production.tfvars" -detailed-exitcode > /dev/null 2>&1; then
    print_status "✅ Production plan generated successfully"
else
    # Exit code 2 means plan would create resources (which is expected)
    if [ $? -eq 2 ]; then
        print_status "✅ Production plan generated successfully (would create resources)"
    else
        print_error "❌ Production plan failed"
        exit 1
    fi
fi

cd ..

# Test 3: Test Ansible Playbooks
print_header "Testing Ansible Playbooks"

cd ansible

print_status "Testing staging playbook syntax..."
if ansible-playbook --syntax-check staging-playbook.yml > /dev/null 2>&1; then
    print_status "✅ Staging playbook syntax is correct"
else
    print_error "❌ Staging playbook syntax check failed"
    exit 1
fi

print_status "Testing production playbook syntax..."
if ansible-playbook --syntax-check production-playbook.yml > /dev/null 2>&1; then
    print_status "✅ Production playbook syntax is correct"
else
    print_error "❌ Production playbook syntax check failed"
    exit 1
fi

cd ..

# Test 4: Test Docker Hub Connectivity
print_header "Testing Docker Hub Connectivity"

print_status "Testing Docker Hub access..."
if docker pull hello-world > /dev/null 2>&1; then
    print_status "✅ Docker Hub connectivity is working"
else
    print_error "❌ Docker Hub connectivity failed"
    exit 1
fi

# Test 5: Test GitHub Workflows
print_header "Testing GitHub Workflows"

print_status "Checking GitHub workflow files..."
if [ -f ".github/workflows/test-secrets.yml" ]; then
    print_status "✅ Test secrets workflow exists"
else
    print_error "❌ Test secrets workflow not found"
    exit 1
fi

if [ -f ".github/workflows/modular-deploy.yml" ]; then
    print_status "✅ Modular deploy workflow exists"
else
    print_error "❌ Modular deploy workflow not found"
    exit 1
fi

# Test 6: Test Application Files
print_header "Testing Application Files"

print_status "Checking Docker Compose configuration..."
if [ -f "docker-compose.yml" ]; then
    print_status "✅ Docker Compose file exists"
else
    print_error "❌ Docker Compose file not found"
    exit 1
fi

print_status "Checking Flask microservices..."
if [ -d "user-service" ] && [ -d "product-service" ] && [ -d "order-service" ] && [ -d "frontend" ]; then
    print_status "✅ All Flask microservices exist"
else
    print_error "❌ Some Flask microservices are missing"
    exit 1
fi

# Test 7: Test Documentation
print_header "Testing Documentation"

print_status "Checking setup documentation..."
if [ -f "GITHUB_SECRETS_SETUP.md" ]; then
    print_status "✅ GitHub secrets setup guide exists"
else
    print_error "❌ GitHub secrets setup guide not found"
    exit 1
fi

if [ -f "setup-github-secrets.sh" ]; then
    print_status "✅ GitHub secrets setup script exists"
else
    print_error "❌ GitHub secrets setup script not found"
    exit 1
fi

# Final Success Message
print_header "All Tests Passed! 🎉"

echo ""
echo "✅ All local tests have passed successfully!"
echo ""
echo "Your local environment is ready for GitHub secrets testing."
echo ""
echo "Next steps:"
echo "1. Set up GitHub secrets using the setup script:"
echo "   ./setup-github-secrets.sh"
echo ""
echo "2. Or manually add secrets to GitHub:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo "   - DOCKERHUB_USERNAME"
echo "   - DOCKERHUB_TOKEN"
echo ""
echo "3. Test the GitHub Actions workflow:"
echo "   - Go to GitHub → Actions tab"
echo "   - Run 'Test GitHub Secrets' workflow"
echo ""
echo "4. Deploy to staging:"
echo "   git checkout -b staging"
echo "   git push origin staging"
echo ""

print_status "Local testing completed successfully!" 