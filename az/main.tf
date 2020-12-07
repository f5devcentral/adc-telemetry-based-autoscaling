# Terraform Version Pinning
terraform {
  required_version = "~> 0.13.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.1.0"
    }
  }
}