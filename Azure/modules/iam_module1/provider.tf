terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.41.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# terraform{
#  backend "azurerm" {
#   resource_group_name = ""
#   storage_account_name = ""
#   container_name = ""
#  key = ""
#   }
# }