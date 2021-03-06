


provider "null" {
  version = "~> 2.1"
}

provider "google" {
  version = "~> 3.45.0"
}

# [START vpc_firewall_create]
resource "google_compute_firewall" "rules" {
  project     = var.project_id # Replace this with your project ID in quotes
  name        = "my-firewall-rule"
  network     = "default"
  description = "Creates firewall rule targeting tagged instances"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000"]
  }
  target_tags = ["web"]
}
# [END vpc_firewall_create]
