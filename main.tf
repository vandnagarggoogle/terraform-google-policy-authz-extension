

# 1. Provision Authz Extensions (Deduplicated via Map Keys)
resource "google_network_services_authz_extension" "extensions" {
  for_each = var.extensions_config

  project               = var.project_id
  location              = var.location
  name                  = each.key
  description           = lookup(each.value, "description", "Managed by ADC Agent Gateway")
  load_balancing_scheme = each.value.load_balancing_scheme
  authority             = each.value.authority
  service               = each.value.backend_service
  timeout               = lookup(each.value, "timeout", "0.1s")
  fail_open             = lookup(each.value, "fail_open", false)
  forward_headers       = lookup(each.value, "forward_headers", [])
}

# 2. Provision Authz Policies
resource "google_network_security_authz_policy" "policies" {
  for_each = var.policies_config

  project     = var.project_id
  location    = var.location
  name        = each.key
  description = lookup(each.value, "description", "Security policy for Agent Gateway")
  action      = each.value.action

  target {
    load_balancing_scheme = each.value.load_balancing_scheme
    resources             = each.value.target_resources
  }

  dynamic "custom_provider" {
    for_each = length(lookup(each.value, "extension_names", [])) > 0 ? [1] : []
    content {
      authz_extension {
        # Links to the IDs of deduplicated extensions created above
        resources = [
          for ext_name in each.value.extension_names :
          google_network_services_authz_extension.extensions[ext_name].id
        ]
      }
    }
  }

  dynamic "http_rules" {
    for_each = lookup(each.value, "http_rules", [])
    content {
      when = lookup(http_rules.value, "when", null)

      dynamic "from" {
        for_each = lookup(http_rules.value, "from", null) != null ? [http_rules.value.from] : []
        content {
          dynamic "not_sources" {
            for_each = lookup(from.value, "not_sources", [])
            content {
              # FIX: ip_blocks is an argument (list of strings), not a block
              ip_blocks = [
                for b in lookup(not_sources.value, "ip_blocks", []) :
                "${b.prefix}/${b.length}"
              ]

              dynamic "principals" {
                for_each = lookup(not_sources.value, "principals", [])
                content {
                  principal_selector = principals.value.principal_selector
                  dynamic "principal" {
                    for_each = [principals.value.principal]
                    content {
                      exact       = principal.value.exact
                      ignore_case = lookup(principal.value, "ignore_case", true)
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "to" {
        for_each = lookup(http_rules.value, "to", null) != null ? [http_rules.value.to] : []
        content {
          dynamic "operations" {
            for_each = lookup(to.value, "operations", [])
            content {
              # FIX: paths is a block, not an argument
              dynamic "paths" {
                for_each = lookup(operations.value, "paths", [])
                content {
                  exact = lookup(paths.value, "exact", null)
                }
              }
              methods = lookup(operations.value, "methods", [])

              dynamic "header_set" {
                for_each = lookup(operations.value, "header_set", [])
                content {
                  dynamic "headers" {
                    for_each = lookup(header_set.value, "headers", [])
                    content {
                      name = headers.value.name
                      dynamic "value" {
                        for_each = [headers.value.value]
                        content {
                          exact       = value.value.exact
                          ignore_case = lookup(value.value, "ignore_case", true)
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}