output "role_assignment_resource" {
  value = azurerm_role_assignment.iam_reader.role_assignment_resource_id
}

output "role_assignment_resource" {
  value = azurerm_role_assignment.network_security.role_assignment_resource_id
}

output "role_assignment_resource" {
  value = azurerm_role_assignment.security_security.role_assignment_resource_id
}