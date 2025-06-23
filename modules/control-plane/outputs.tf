/*
 * Outputs for the DATA PLANE to connect to... Konnect
 */
output "control_plane_hostname" {
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
  sensitive = true
}

/*
 * Output for the Konnect Terraform Provider to create more resources
 */
output "control_plane_id" {
  value = konnect_gateway_control_plane.this.id
}
