

output "service_projects" {
  description = "Project ids of the services with access to all subnets."
  value       = google_compute_shared_vpc_service_project.projects.*.service_project
}
