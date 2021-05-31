

provider "null" {
  version = "~> 2.1"
}

provider "google" {
  version = "~> 3.45.0"
}

# [START vpc_peering_create]
module "peering1" {
  source        = "terraform-google-modules/network/google//modules/network-peering"
  version       = "~> 3.2.1"
  local_network = var.local_network # Replace with self link to VPC network "foobar" in quotes
  peer_network  = var.peer_network  # Replace with self link to VPC network "other" in quotes
}
# [END vpc_peering_create]
