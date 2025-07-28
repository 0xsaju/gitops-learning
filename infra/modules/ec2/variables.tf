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

variable "subnet_id" {
  description = "ID of the subnet where the instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
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

variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
} 