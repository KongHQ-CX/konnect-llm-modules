variable "llms" {
  description = "LLMs to apply to the control plane"
  type        = any
  default     = []
}

variable "consumers" {
  description = "Consumers to apply to the control plane"
  type        = any
  default     = []
}

variable "control_plane_id" {
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
