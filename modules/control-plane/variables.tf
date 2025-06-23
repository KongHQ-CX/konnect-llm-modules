
variable "name" {
  description = "Universal name to apply to the control-plane, and its associated resources."
  type        = string
}

variable "cert_organization" {
  type = string
}

variable "konnect_token" {
  description = "Konnect personal access token"
  type        = string
  sensitive   = true
}

variable "konnect_server_url" {
  description = "Konnect server URL"
  type        = string
  default     = "https://eu.api.konghq.com"
}
