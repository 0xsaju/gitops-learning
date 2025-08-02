# ALB Controller Module - variables.tf

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC Provider ARN for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 