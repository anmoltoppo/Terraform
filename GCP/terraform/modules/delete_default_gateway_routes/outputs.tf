

output "project_id" {
  value       = var.project_id
  description = "The ID of the project being used"
}

output "network_name" {
  value       = module.example.network_name
  description = "The name of the VPC being created"
}
