##### Role Definition #####

resource "azurerm_role_definition" "security_reader" {
 name = "Security-Reader"
 scope = var.azurerm_subscription.primary.id
 description = "Read Access to IAM Resources"

 permissions {
 actions = [
          "Microsoft.Authorization/*/read",
          "Microsoft.Insights/alertRules/*",
          "Microsoft.Insights/components/*",
          "Microsoft.ResourceHealth/availabilityStatuses/read",
          "Microsoft.Resources/subscriptions/resourceGroups/read"
        ]
 not_actions = []
}

assignable_scopes = var.azurerm_subscription.primary.id
}

##### Role Assignment #####

resource "azurerm_role_assignment" "security_reader" {
 scope = var.azurerm_subscription.primary.id
 role_definition_id = azurerm_role_definition.security_reader.id
 role_definition_name = "Reader"
 principal_id = var.azurerm_principle_id.object_id
}