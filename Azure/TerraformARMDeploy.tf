provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.41.0"
    }
  }
}

variable "resource_group_name" {
  type        = string
  description = "RG name in Azure"
}

variable "location" {
  type        = string
  description = "RG location in Azure"
}

variable "storage_account_name" {
  type        = string
  description = "Storage Account name in Azure"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_template_deployment" "arm" {
  name                = "arm-deploy"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Complete" # "Incremental"
  template_body       = file("arm_template.json")

  parameters = {
    storageAccountName = var.storage_account_name
    storageAccountType = "Standard_LRS"
  }
}

# azurerm_resource_group_template_deployment is replacing azurerm_template_deployment
# src: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment
#
# resource "azurerm_resource_group_template_deployment" "arm" {
# }