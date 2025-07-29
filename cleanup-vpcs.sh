#!/bin/bash

# Cleanup script for staging VPCs
set -e

REGION="ap-southeast-1"
ENVIRONMENT="staging"

echo "🧹 Cleaning up staging VPCs and dependencies..."

# Get all staging VPCs
VPCS=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=${ENVIRONMENT}-vpc" --query 'Vpcs[*].VpcId' --output text)

if [ -z "$VPCS" ]; then
    echo "No staging VPCs found"
    exit 0
fi

echo "Found VPCs: $VPCS"

for VPC_ID in $VPCS; do
    echo "Processing VPC: $VPC_ID"
    
    # Get subnets in this VPC
    SUBNETS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text)
    
    if [ -n "$SUBNETS" ]; then
        echo "  Deleting subnets: $SUBNETS"
        for SUBNET_ID in $SUBNETS; do
            aws ec2 delete-subnet --region $REGION --subnet-id $SUBNET_ID
        done
    fi
    
    # Get route tables in this VPC (excluding main route table)
    ROUTE_TABLES=$(aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=false" --query 'RouteTables[*].RouteTableId' --output text)
    
    if [ -n "$ROUTE_TABLES" ]; then
        echo "  Deleting route tables: $ROUTE_TABLES"
        for RT_ID in $ROUTE_TABLES; do
            aws ec2 delete-route-table --region $REGION --route-table-id $RT_ID
        done
    fi
    
    # Get internet gateways attached to this VPC
    IGWS=$(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].InternetGatewayId' --output text)
    
    if [ -n "$IGWS" ]; then
        echo "  Detaching and deleting internet gateways: $IGWS"
        for IGW_ID in $IGWS; do
            aws ec2 detach-internet-gateway --region $REGION --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
            aws ec2 delete-internet-gateway --region $REGION --internet-gateway-id $IGW_ID
        done
    fi
    
    # Get security groups in this VPC (excluding default)
    SGS=$(aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=!default" --query 'SecurityGroups[*].GroupId' --output text)
    
    if [ -n "$SGS" ]; then
        echo "  Deleting security groups: $SGS"
        for SG_ID in $SGS; do
            aws ec2 delete-security-group --region $REGION --group-id $SG_ID
        done
    fi
    
    # Finally delete the VPC
    echo "  Deleting VPC: $VPC_ID"
    aws ec2 delete-vpc --region $REGION --vpc-id $VPC_ID
    
    echo "  ✅ VPC $VPC_ID deleted successfully"
done

echo "🎉 All staging VPCs cleaned up successfully!" 