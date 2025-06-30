resource "konnect_gateway_consumer" "this_each" {
  for_each = { for consumer in var.consumers : consumer.username => consumer }
  control_plane_id = var.control_plane_id

  username   = each.value.username
}

resource "konnect_gateway_key_auth" "this_each" {
  for_each = { for consumer in var.consumers : consumer.username => consumer }

  consumer_id      = konnect_gateway_consumer.this_each[each.key].id
  control_plane_id = var.control_plane_id

  key = random_string.random[each.key].result
}

resource "random_string" "random" {
  for_each = { for consumer in var.consumers : consumer.username => consumer }

  length           = 32
  special          = false
  override_special = "/@£$"
}

output "consumer_keys" {
  value = {
    for consumer in var.consumers : consumer.username => konnect_gateway_key_auth.this_each[consumer.username].key
  }
}
