

locals {
  network_name = "delete-gw-routes-${var.random_string_for_testing}"
}

module "example" {
  source       = "../../../examples/delete_default_gateway_routes"
  project_id   = var.project_id
  network_name = local.network_name
}
