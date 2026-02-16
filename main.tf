/**
 * Unit Kind 3: Authz Policies and Extensions
 * This module provisions the security layer for the Universal Agent Gateway.
 * It ensures many-to-many relationships and deduplicated extension creation.
 */

# 1. Provision Authz Extensions (Deduplicated via Map Keys)
resource "google_network_services_authz_extension" "extensions" {
  for_each = var.extensions_config

  project               = var.project_id
  location              = var.location
  name                  = each.key
  description           = lookup(each.value, "description", "Managed by ADC")
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
    # Only create the provider block if extensions are linked
    for_each = length(lookup(each.value, "extension_names", [])) > 0 ? [1] : []
    content {
      authz_extension {
        # Dynamically links to the IDs of the extensions created in the first step
        resources = [
          for ext_name in each.value.extension_names :
          google_network_services_authz_extension.extensions[ext_name].id
        ]
      }
    }
  }

  # Map structured HTTP rules (from, to, when)
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
              # CORRECTED: ip_blocks is a list of strings (e.g., ["192.168.1.0/24"])
              ip_blocks = lookup(not_sources.value, "ip_blocks", [])

              # CORRECTED: principals is a list of strings (e.g., ["spiffe://my-domain/ns/default/sa/my-sa"])
              principals = lookup(not_sources.value, "principals", [])

              # Add other source fields if needed, e.g.:
              namespaces         = lookup(not_sources.value, "namespaces", [])
              request_principals = lookup(not_sources.value, "request_principals", [])
            }
          }
          # You can also include a "sources" block if needed:
          dynamic "sources" {
            for_each = lookup(from.value, "sources", [])
            content {
              ip_blocks          = lookup(sources.value, "ip_blocks", [])
              principals         = lookup(sources.value, "principals", [])
              namespaces         = lookup(sources.value, "namespaces", [])
              request_principals = lookup(sources.value, "request_principals", [])
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
              # paths is a list of PathMatcher objects, each with an "exact" field
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
