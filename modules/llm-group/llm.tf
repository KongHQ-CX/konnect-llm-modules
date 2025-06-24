# This will hold all LLMs for this stack, so we can apply "global" policies
resource "konnect_gateway_service" "ai_sink" {
  name             = "ai-sink"
  protocol         = "https"
  host             = "ai.gateway.local"
  port             = 443
  path             = "/"
  control_plane_id = var.control_plane_id
}

resource "konnect_gateway_route" "ai_routes" {
  for_each = { for llm in var.llms : llm.name => llm }

  methods = ["POST"]
  name    = "llm-${each.value.name}"
  paths   = [ "~${each.value.base_path}" ]
  headers = {
    "x-model" = [
      each.value.name
    ]
  }

  control_plane_id = var.control_plane_id
  service = {
    id = konnect_gateway_service.ai_sink.id
  }
}

resource "konnect_gateway_plugin_ai_proxy_advanced" "ai_plugins" {
  for_each = { for llm in var.llms : llm.name => llm }

  config = {
    balancer = {
      algorithm = "round-robin"
      failover_criteria = [
        "http_403",
        "http_429"
      ]
      tokens_count_strategy = "total-tokens"
    }

    llm_format            = each.value.llm_format
    max_request_body_size = 10000
    model_name_header     = true
    
    targets = toset([
      for target in each.value.targets : {
        auth = {
          allow_override          = target.auth.allow_override
          gcp_use_service_account = target.auth.gcp_use_service_account
        }
        model = {
          name     = target.model.name
          options  = target.model.options
          provider = target.model.provider
        }
        logging = target.logging
        route_type = "llm/v1/chat"
        weight     = 100
      }
    ])
  }

  control_plane_id = var.control_plane_id
  route = {
    id = konnect_gateway_route.ai_routes[each.key].id
  }

  depends_on = [
    konnect_gateway_service.ai_sink
  ]
}
