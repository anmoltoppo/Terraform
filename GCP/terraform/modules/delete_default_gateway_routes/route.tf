

resource "google_compute_route" "alternative_gateway" {
  project = var.project_id
  network = module.example.network_name

  name             = "alternative-gateway-route"
  description      = "Alternative gateway route"
  dest_range       = "0.0.0.0/0"
  tags             = ["egress-inet"]
  next_hop_gateway = "default-internet-gateway"
}
