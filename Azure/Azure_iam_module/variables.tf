variable "subscriptionID" {
    default = string
    description = "Value of the subcription ID"  

}

variable "managementGroupName" {
    default = string
    description = "Value of the managemnet group"
  
}

variable "location" {
    default = string
    description = "Value of the location"
  
}

variable "resourceGroupName" {
    default = string
    description = "Value of the resource group"
  
}

variable "groupID" {
    default = string
    description = "Value of the Azure AD group"
  
}

variable "scopeID" {
    default = string
    description = "Value of the Azure AD group"
    # "/subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/myGroup" 
    # The scope at which the Role Assignment applies to
}

variable "enviroment" {
    description = "Value of the enviroment"
    type = map
    default = {

        "infrastructure_ID" = "string"
        "system_ID" = "string"
    }
    validation = {
        condition     = var.Enviroment == "Dev" || var.Enviroment == "QA" || var.Enviroment == "Test" || var.Enviroment == "Prod"
        error_message = "The Enviroment value is invalid, Allow value (Dev,QA,Test,Prod)"
    }
  
}
