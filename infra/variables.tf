# AWS Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "gitops-learning"
}

variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "devops-team"
}

# Network Configuration
variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "ap-southeast-1a"
}

# Security Configuration
variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidr_blocks" {
  description = "CIDR blocks allowed for HTTP/HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_database_cidr_blocks" {
  description = "CIDR blocks allowed for database access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "expose_database_ports" {
  description = "Whether to expose database ports externally"
  type        = bool
  default     = false
}

# EC2 Configuration
variable "ami_id" {
  description = "AMI ID for the EC2 instance. If null, will use latest Ubuntu 22.04"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair to use"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

variable "encrypt_volumes" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key to add to authorized_keys"
  type        = string
  default     = ""
}

variable "instance_password" {
  description = "Password for the ubuntu user"
  type        = string
  default     = "Ubuntu2024!"
}

variable "allocate_eip" {
  description = "Whether to allocate an Elastic IP"
  type        = bool
  default     = false
} 