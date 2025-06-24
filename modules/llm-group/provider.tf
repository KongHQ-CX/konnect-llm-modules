terraform {
  required_providers {
    konnect = {
      source  = "Kong/konnect"
      version = "2.10.0"
    }
  }
}

provider "konnect" {
  konnect_access_token = var.konnect_token
  server_url = var.konnect_server_url
}
