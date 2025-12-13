variable "project_name" {
  description = "Prefix for AWS resources"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (Ubuntu 22.04 recommended)"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of SSH key pair in AWS"
  type        = string
}

variable "bootstrap_bucket" {
  description = "S3 bucket that stores bootstrap scripts"
  type        = string
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "public_key_path" {
  description = "Local path to SSH public key"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

#=====================ECR===============
variable "ecr_repos" {
  description = "List of microservice repositories to create"
  type        = list(string)
}
