#!/bin/bash

# Staging Deployment Monitor
# This script helps monitor the staging deployment progress

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

print_header "Staging Deployment Monitor"

echo ""
echo "This script will help you monitor the staging deployment progress."
echo ""

# Check if AWS CLI is configured
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    print_warning "AWS credentials not configured. You can still monitor GitHub Actions."
    AWS_AVAILABLE=false
else
    print_status "AWS credentials configured. Monitoring both GitHub Actions and AWS."
    AWS_AVAILABLE=true
fi

echo ""
print_header "Monitoring Steps"

echo "1. GitHub Actions Status:"
echo "   - Go to: https://github.com/0xsaju/gitops-learning/actions"
echo "   - Look for 'Modular Terraform Deployment' workflow"
echo "   - Check if it's running or completed"
echo ""

if [ "$AWS_AVAILABLE" = true ]; then
    echo "2. AWS Infrastructure Status:"
    echo "   - Go to: https://console.aws.amazon.com/ec2/v2/home"
    echo "   - Look for instance named 'staging-flask-microservices'"
    echo "   - Check instance state (should be 'running')"
    echo ""
    
    echo "3. Application Endpoints (once deployed):"
    echo "   - Frontend: http://<instance-ip>:8080"
    echo "   - User API: http://<instance-ip>:5001"
    echo "   - Product API: http://<instance-ip>:5002"
    echo "   - Order API: http://<instance-ip>:5003"
    echo ""
fi

echo "4. Expected Timeline:"
echo "   - Docker build & push: 5-10 minutes"
echo "   - Infrastructure creation: 3-5 minutes"
echo "   - Application deployment: 2-3 minutes"
echo "   - Total: ~10-15 minutes"
echo ""

# Function to check AWS resources
check_aws_resources() {
    if [ "$AWS_AVAILABLE" = false ]; then
        return
    fi
    
    print_header "Checking AWS Resources"
    
    # Check for staging instance
    print_status "Looking for staging EC2 instance..."
    INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=staging-flask-microservices" \
        --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
        --output table 2>/dev/null || echo "No instances found")
    
    if [[ $INSTANCE_ID == *"running"* ]]; then
        print_status "✅ Staging instance is running!"
        # Extract IP address
        IP=$(echo "$INSTANCE_ID" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        if [ -n "$IP" ]; then
            echo "   Instance IP: $IP"
            echo "   Frontend URL: http://$IP:8080"
            echo "   User API: http://$IP:5001"
            echo "   Product API: http://$IP:5002"
            echo "   Order API: http://$IP:5003"
        fi
    elif [[ $INSTANCE_ID == *"pending"* ]]; then
        print_warning "⏳ Staging instance is starting..."
    else
        print_warning "⚠️  Staging instance not found or not running"
    fi
    
    # Check for VPC
    print_status "Looking for staging VPC..."
    VPC_ID=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=staging-vpc" \
        --query 'Vpcs[*].[VpcId,State]' \
        --output table 2>/dev/null || echo "No VPC found")
    
    if [[ $VPC_ID == *"available"* ]]; then
        print_status "✅ Staging VPC is available"
    else
        print_warning "⚠️  Staging VPC not found or not available"
    fi
}

# Function to test application endpoints
test_endpoints() {
    if [ "$AWS_AVAILABLE" = false ]; then
        return
    fi
    
    # Get instance IP
    IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=staging-flask-microservices" "Name=instance-state-name,Values=running" \
        --query 'Reservations[*].Instances[*].PublicIpAddress' \
        --output text 2>/dev/null)
    
    if [ -n "$IP" ] && [ "$IP" != "None" ]; then
        print_header "Testing Application Endpoints"
        
        # Test frontend
        print_status "Testing frontend (http://$IP:8080)..."
        if curl -s -f "http://$IP:8080" > /dev/null 2>&1; then
            print_status "✅ Frontend is accessible"
        else
            print_warning "⚠️  Frontend not accessible yet"
        fi
        
        # Test user API
        print_status "Testing user API (http://$IP:5001)..."
        if curl -s -f "http://$IP:5001/health" > /dev/null 2>&1; then
            print_status "✅ User API is accessible"
        else
            print_warning "⚠️  User API not accessible yet"
        fi
        
        # Test product API
        print_status "Testing product API (http://$IP:5002)..."
        if curl -s -f "http://$IP:5002/health" > /dev/null 2>&1; then
            print_status "✅ Product API is accessible"
        else
            print_warning "⚠️  Product API not accessible yet"
        fi
        
        # Test order API
        print_status "Testing order API (http://$IP:5003)..."
        if curl -s -f "http://$IP:5003/health" > /dev/null 2>&1; then
            print_status "✅ Order API is accessible"
        else
            print_warning "⚠️  Order API not accessible yet"
        fi
    fi
}

# Main monitoring loop
echo "Starting monitoring loop... (Press Ctrl+C to stop)"
echo ""

while true; do
    clear
    print_header "Staging Deployment Monitor"
    echo "Last updated: $(date)"
    echo ""
    
    check_aws_resources
    echo ""
    test_endpoints
    echo ""
    
    echo "Press Ctrl+C to stop monitoring"
    echo "Refreshing in 30 seconds..."
    sleep 30
done 