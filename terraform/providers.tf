terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region  = var.region
  profile = "vadim-student"
}

provider "kubernetes" {
  # Forces the provider to use the default path
  config_path    = "~/.kube/config" 
  
  # Crucial: Forces the provider to use the working context
  config_context = "kubernetes-admin@kubernetes" 
}
