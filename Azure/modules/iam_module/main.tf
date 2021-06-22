provider "azurerm" {
  version = "~>2.0"
  subscription_id = var.subscriptionID
}

# resource "azure_management_group" "iam" {
#     name = var.managementGroupName
#     location = var.location
    
#     tags = {
#         enviroment = var.enviroment
#     }
# }

resource "azure_resource_group" "iam_group" {
    name = var.resourceGroupName
    location = var.location
    
    tags = var.enviroment
}

###### Role Assignment ######

resource "azurerm_role_assignment" "iam_reader" {
 scope = var.scopeID 
 role_definition_id = azurerm_role_definition.iam_reader.role_definition_resource_id
 principal_id = var.groupID # The ID of the Principal Group to assign the Role Definition to.# 
 tags = var.enviroment
}

