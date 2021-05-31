

terraform {
  required_version = ">= 0.13.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "<4.0,>= 2.12"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "<4.0,>= 2.12"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-network:fabric-net-svpc-access/v3.2.2"
  }
  provider_meta "google-beta" {
    module_name = "blueprints/terraform/terraform-google-network:fabric-net-svpc-access/v3.2.2"
  }
}
