###### Role Definition ######

resource "azurerm_role_definition" "iam_reader" {
 name = "Iam-reader"
 role_definition_name = "Reader"
 scope = var.subscriptionID
 description = "IAM Reader Role Definition"

 permissions {
 actions = [
          "Microsoft.Authorization/*/read",
          "Microsoft.Insights/alertRules/*",
          "Microsoft.Insights/components/*",
          "Microsoft.ResourceHealth/availabilityStatuses/read",
          "Microsoft.Resources/subscriptions/resourceGroups/read",
          "Microsoft.Web/listSitesAssignedToHostName/read",
          "Microsoft.Web/serverFarms/read",
          "Microsoft.Web/sites/stop/Action",
          "Microsoft.Web/sites/start/Action",
          "Microsoft.Web/sites/restart/Action",
          "Microsoft.Web/sites/Read",
          "Microsoft.Web/*/read"
        ]
 not_actions = []
}

assignable_scopes = var.subscriptionID
tags = var.enviroment
}
