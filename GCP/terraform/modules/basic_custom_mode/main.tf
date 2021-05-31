
provider "null" {
  version = "~> 2.1"
}

provider "google" {
  version = "~> 3.45.0"
}

# [START vpc_custom_create]
resource "google_compute_network" "vpc_network" {
  project                 = var.project_id # Replace this with your project ID in quotes
  name                    = "my-custom-mode-network"
  auto_create_subnetworks = false
  mtu                     = 1460
}
# [END vpc_custom_create]
