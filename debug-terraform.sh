#!/bin/bash

echo "🔍 Terraform Debug Script"
echo "========================="

cd infra

echo ""
echo "1. Checking Terraform state..."
terraform state list

echo ""
echo "2. Checking Terraform outputs..."
terraform output

echo ""
echo "3. Checking specific instance_public_ip output..."
terraform output -raw instance_public_ip 2>/dev/null || echo "ERROR: instance_public_ip output not found"

echo ""
echo "4. Checking AWS EC2 instances..."
aws ec2 describe-instances --filters "Name=tag:Project,Values=gitops-learning" "Name=tag:Environment,Values=staging" --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table

echo ""
echo "5. Checking S3 state files..."
echo "Staging state:"
aws s3 ls s3://gitops-learning-terraform-state-1753704333/staging/terraform.tfstate 2>/dev/null || echo "No staging state file"
echo "Production state:"
aws s3 ls s3://gitops-learning-terraform-state-1753704333/production/terraform.tfstate 2>/dev/null || echo "No production state file"

echo ""
echo "Debug complete!" 