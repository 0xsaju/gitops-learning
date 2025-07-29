#!/bin/bash

echo "🚀 GitOps Learning - Deployment Status Checker"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 GitHub Actions Status:${NC}"
echo "🌐 https://github.com/0xsaju/gitops-learning/actions"
echo ""

echo -e "${BLUE}☁️ AWS Console Links:${NC}"
echo "EC2 Instances: https://console.aws.amazon.com/ec2/v2/home?region=ap-southeast-1#Instances:"
echo "VPC: https://console.aws.amazon.com/vpc/home?region=ap-southeast-1#vpcs:"
echo "Security Groups: https://console.aws.amazon.com/vpc/home?region=ap-southeast-1#SecurityGroups:"
echo ""

echo -e "${BLUE}🔍 Expected Deployment Steps:${NC}"
echo "1. ✅ Build and push Docker images (user, product, order, frontend)"
echo "2. 🔄 Deploy infrastructure with Terraform (VPC, EC2, Security Groups)"
echo "3. 🔄 Deploy application with Ansible (Docker, Docker Compose)"
echo "4. 🔄 Health check all services"
echo ""

echo -e "${BLUE}🎯 Expected Endpoints (after deployment):${NC}"
echo "Frontend: http://[SERVER_IP]:8080"
echo "User Service: http://[SERVER_IP]:5001"
echo "Product Service: http://[SERVER_IP]:5002"
echo "Order Service: http://[SERVER_IP]:5003"
echo ""

echo -e "${YELLOW}💡 Tips:${NC}"
echo "- Check GitHub Actions for real-time progress"
echo "- Look for green checkmarks ✅ for completed jobs"
echo "- Red X marks ❌ indicate failures"
echo "- The deployment takes ~10-15 minutes total"
echo ""

echo -e "${GREEN}🎉 Ready to monitor your deployment!${NC}" 