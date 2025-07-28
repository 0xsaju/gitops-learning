#!/bin/bash

# GitHub Secrets Setup Script
# This script helps you set up the required GitHub secrets for automated deployment

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

print_header "GitHub Secrets Setup Guide"

echo ""
echo "This script will help you set up the required GitHub secrets for automated deployment."
echo ""
echo "Required secrets:"
echo "1. AWS_ACCESS_KEY_ID"
echo "2. AWS_SECRET_ACCESS_KEY"
echo "3. DOCKERHUB_USERNAME"
echo "4. DOCKERHUB_TOKEN"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    print_warning "GitHub CLI (gh) is not installed."
    echo "You can install it from: https://cli.github.com/"
    echo "Or manually add secrets through GitHub web interface."
    echo ""
    echo "Manual setup instructions:"
    echo "1. Go to your GitHub repository"
    echo "2. Click Settings → Secrets and variables → Actions"
    echo "3. Add the following secrets:"
    echo "   - AWS_ACCESS_KEY_ID"
    echo "   - AWS_SECRET_ACCESS_KEY"
    echo "   - DOCKERHUB_USERNAME"
    echo "   - DOCKERHUB_TOKEN"
    echo ""
    exit 0
fi

# Check if user is authenticated with GitHub
if ! gh auth status &> /dev/null; then
    print_error "You are not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    exit 1
fi

# Get repository information
REPO_URL=$(git remote get-url origin)
if [[ $REPO_URL == *"github.com"* ]]; then
    REPO_NAME=$(echo $REPO_URL | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\)\.git.*/\1/')
    print_status "Detected repository: $REPO_NAME"
else
    print_error "Not a GitHub repository or remote not configured."
    exit 1
fi

echo ""
print_header "Setting up GitHub Secrets"

# Function to add secret
add_secret() {
    local secret_name=$1
    local secret_value=$2
    local description=$3
    
    echo ""
    print_status "Adding secret: $secret_name"
    echo "Description: $description"
    
    if gh secret set "$secret_name" --repo "$REPO_NAME" --body "$secret_value"; then
        print_status "✅ Successfully added $secret_name"
    else
        print_error "❌ Failed to add $secret_name"
        return 1
    fi
}

# AWS Credentials
echo ""
print_header "AWS Credentials Setup"

echo "You need to provide your AWS access key and secret access key."
echo "If you don't have them:"
echo "1. Go to AWS Console → IAM → Users → Your User"
echo "2. Click 'Security credentials' tab"
echo "3. Click 'Create access key'"
echo "4. Choose 'Application running outside AWS'"
echo ""

read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -s -p "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo ""

if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    print_error "AWS credentials cannot be empty."
    exit 1
fi

# Docker Hub Credentials
echo ""
print_header "Docker Hub Credentials Setup"

echo "You need to provide your Docker Hub username and access token."
echo "If you don't have an access token:"
echo "1. Go to Docker Hub → Account Settings → Security"
echo "2. Click 'New Access Token'"
echo "3. Give it a name (e.g., 'GitHub Actions')"
echo "4. Copy the token (you won't see it again!)"
echo ""

read -p "Enter your Docker Hub username: " DOCKERHUB_USERNAME
read -s -p "Enter your Docker Hub access token: " DOCKERHUB_TOKEN
echo ""

if [[ -z "$DOCKERHUB_USERNAME" || -z "$DOCKERHUB_TOKEN" ]]; then
    print_error "Docker Hub credentials cannot be empty."
    exit 1
fi

# Confirm before adding secrets
echo ""
print_header "Confirmation"

echo "About to add the following secrets to repository: $REPO_NAME"
echo ""
echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:0:4}..."
echo "AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY:0:4}..."
echo "DOCKERHUB_USERNAME: $DOCKERHUB_USERNAME"
echo "DOCKERHUB_TOKEN: ${DOCKERHUB_TOKEN:0:4}..."
echo ""

read -p "Do you want to proceed? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    print_warning "Setup cancelled."
    exit 0
fi

# Add secrets
print_header "Adding Secrets to GitHub"

add_secret "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY_ID" "AWS access key for infrastructure deployment"
add_secret "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET_ACCESS_KEY" "AWS secret access key for infrastructure deployment"
add_secret "DOCKERHUB_USERNAME" "$DOCKERHUB_USERNAME" "Docker Hub username for image publishing"
add_secret "DOCKERHUB_TOKEN" "$DOCKERHUB_TOKEN" "Docker Hub access token for image publishing"

echo ""
print_header "Setup Complete!"

echo "✅ All secrets have been added to your GitHub repository."
echo ""
echo "Next steps:"
echo "1. Test the secrets by running the test workflow:"
echo "   - Go to your repository → Actions tab"
echo "   - Find 'Test GitHub Secrets' workflow"
echo "   - Click 'Run workflow'"
echo ""
echo "2. Deploy to staging:"
echo "   git checkout -b staging"
echo "   git push origin staging"
echo ""
echo "3. Monitor deployment:"
echo "   - Check GitHub Actions tab for progress"
echo "   - Verify infrastructure creation in AWS"
echo "   - Test application endpoints"
echo ""

print_status "GitHub secrets setup completed successfully!" 