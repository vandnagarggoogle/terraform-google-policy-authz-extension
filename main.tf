/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Unit Kind 3: Authz Policies and Extensions
 * This module provisions the security layer for the Agent Gateway.
 * It ensures many-to-many relationships and deduplicated extension creation.
 */

# 1. Provision Authz Extensions (Internal Map Conversion for Deduplication)
resource "google_network_services_authz_extension" "extensions" {
  for_each = { for e in var.extensions_config : e.name => e }
  
  provider = google-beta

  project               = var.project_id
  location              = var.location
  name                  = each.key
  load_balancing_scheme = each.value.load_balancing_scheme
  authority             = each.value.authority
  service               = each.value.backend_service
  timeout               = each.value.timeout
  fail_open             = each.value.fail_open
  forward_headers       = each.value.forward_headers
}

# 2. Provision Authz Policies
resource "google_network_security_authz_policy" "policies" {
  for_each = { for p in var.policies_config : p.name => p }

  provider = google-beta

  project  = var.project_id
  location = var.location
  name     = each.key
  action   = each.value.action

  target {
    load_balancing_scheme = each.value.load_balancing_scheme
    resources             = each.value.target_resources
  }

  dynamic "custom_provider" {
    # Trigger if either IAP or an Extension is requested
    for_each = each.value.action == "CUSTOM" ? [1] : []
    content {
      dynamic "cloud_iap" {
        for_each = each.value.iap_enabled ? [1] : []
        content {
          enabled = true
        }
      }

      dynamic "authz_extension" {
        for_each = (!each.value.iap_enabled && each.value.extension_name != null) ? [1] : []
        content {
          resources = [
            google_network_services_authz_extension.extensions[each.value.extension_name].id
          ]
        }
      }
    }
  }

  # Dynamic HTTP rules mapping
  dynamic "http_rules" {
    for_each = each.value.http_rules
    content {
      when = http_rules.value.when

      dynamic "from" {
        for_each = http_rules.value.from != null ? [http_rules.value.from] : []
        content {
          dynamic "not_sources" {
            for_each = from.value.not_sources
            content {
              # ip_blocks is a REPEATED BLOCK in v7.x
              dynamic "ip_blocks" {
                for_each = not_sources.value.ip_blocks
                content {
                  prefix = ip_blocks.value.prefix
                  length = ip_blocks.value.length
                }
              }

              dynamic "principals" {
                for_each = not_sources.value.principals
                content {
                  principal_selector = principals.value.principal_selector
                  dynamic "principal" {
                    for_each = principals.value.principal != null ? [principals.value.principal] : []
                    content {
                      exact       = principal.value.exact
                      ignore_case = principal.value.ignore_case
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "to" {
        for_each = http_rules.value.to != null ? [http_rules.value.to] : []
        content {
          dynamic "operations" {
            for_each = to.value.operations
            content {
              methods = operations.value.methods
              dynamic "paths" {
                for_each = operations.value.paths
                content {
                  exact = paths.value.exact
                }
              }
              dynamic "header_set" {
                for_each = operations.value.header_set
                content {
                  dynamic "headers" {
                    for_each = header_set.value.headers
                    content {
                      name = headers.value.name
                      dynamic "value" {
                        for_each = headers.value.value != null ? [headers.value.value] : []
                        content {
                          exact       = value.value.exact
                          ignore_case = value.value.ignore_case
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
