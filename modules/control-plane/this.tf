resource "konnect_gateway_control_plane" "this" {
  name = var.name

  auth_type     = "pinned_client_certs"
  cloud_gateway = false
  cluster_type  = "CLUSTER_TYPE_CONTROL_PLANE"

  description   = "${var.name} Control Plane."
}

# ECDSA key with P384 elliptic curve
resource "tls_private_key" "this" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name  = "${var.name}-control-plane"
    organization = var.cert_organization
  }

  validity_period_hours = 7200

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "konnect_gateway_data_plane_client_certificate" "this" {
  cert             = tls_self_signed_cert.this.cert_pem
  control_plane_id = konnect_gateway_control_plane.this.id
}

output "control_plane_hostnamee" {
  value = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<authority>[^/?#]*))?", konnect_gateway_control_plane.this.config.control_plane_endpoint)["authority"]
}

output "telemetry_hostname" {
  value = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<authority>[^/?#]*))?", konnect_gateway_control_plane.this.config.telemetry_endpoint)["authority"]
}

output "cluster_cert_pem" {
  value = tls_self_signed_cert.this.cert_pem
}

output "cluster_cert_key_pem" {
  value = tls_private_key.this.private_key_pem
}

output "control_plane_id" {
  value = konnect_gateway_control_plane.this.id
}
