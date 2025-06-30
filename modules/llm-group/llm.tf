# This will hold all LLMs for this stack, so we can apply "global" policies
resource "konnect_gateway_service" "ai_sink" {
  name             = "ai-sink"
  protocol         = "https"
  host             = "ai.gateway.local"
  port             = 443
  path             = "/"
  control_plane_id = var.control_plane_id
}

resource "konnect_gateway_consumer_group" "large" {
  name             = "large"
  control_plane_id = var.control_plane_id
}
resource "konnect_gateway_plugin_ai_rate_limiting_advanced" "large_tshirt_budget" {
  for_each = { for llm in var.llms : llm.name => llm }

  route = {
    id = konnect_gateway_route.ai_routes[each.key].id
  }

  consumer_group = {
    id = konnect_gateway_consumer_group.large.id
  }
  
  instance_name = "${each.value.name}_large"

  control_plane_id = var.control_plane_id

  config = {
    llm_providers = [
      {
        name = "gemini",
        limit = lookup(each.value.tshirt, "large", each.value.tshirt.small).limit
        window_size = lookup(each.value.tshirt, "large", each.value.tshirt.small).window_size
      },
    ],
    redis = {
      host = "redis-master",
      port = 6379,
      # ssl = true,
      password = "root"
    },
    strategy = "redis",
    sync_rate = "0.5"
  }
}

resource "konnect_gateway_consumer_group" "medium" {
  name             = "medium"
  control_plane_id = var.control_plane_id
}
resource "konnect_gateway_plugin_ai_rate_limiting_advanced" "medium_tshirt_budget" {
  for_each = { for llm in var.llms : llm.name => llm }

  route = {
    id = konnect_gateway_route.ai_routes[each.key].id
  }

  consumer_group = {
    id = konnect_gateway_consumer_group.medium.id
  }

  instance_name = "${each.value.name}_medium"

  control_plane_id = var.control_plane_id

  config = {
    llm_providers = [
      {
        name = "gemini",
        limit = lookup(each.value.tshirt, "medium", each.value.tshirt.small).limit
        window_size = lookup(each.value.tshirt, "medium", each.value.tshirt.small).window_size
      },
    ],
    redis = {
      host = "redis-master",
      port = 6379,
      # ssl = true,
      password = "root"
    },
    strategy = "redis",
    sync_rate = "0.5"
  }
}

resource "konnect_gateway_plugin_key_auth" "key_auth" {
  service = {
    id = konnect_gateway_service.ai_sink.id
  }

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

resource "konnect_gateway_plugin_ai_rate_limiting_advanced" "small_tshirt_budget" {
  for_each = { for llm in var.llms : llm.name => llm }

  route = {
    id = konnect_gateway_route.ai_routes[each.key].id
  }

  control_plane_id = var.control_plane_id

  config = {
    llm_providers = [
      {
        name = "gemini",
        limit = each.value.tshirt.small.limit
        window_size = each.value.tshirt.small.window_size
      },
    ],
    redis = {
      host = "redis-master",
      port = 6379,
      # ssl = true,
      password = "root"
    },
    strategy = "redis",
    sync_rate = "0.5"
  }
}

resource "konnect_gateway_plugin_ai_proxy_advanced" "ai_rate_limiting_advanced_plugin_tshirt_small" {
  for_each = { for llm in var.llms : llm.name => llm }

  control_plane_id = var.control_plane_id
  route = {
    id = konnect_gateway_route.ai_routes[each.key].id
  }

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
        route_type = each.value.route_type
        weight     = 100
      }
    ])
  }

  depends_on = [
    konnect_gateway_service.ai_sink
  ]
}
