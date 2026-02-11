/**
 * Copyright 2021 Google LLC
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

  # Link to the Load Balancer Forwarding Rule
  target {
    load_balancing_scheme = each.value.load_balancing_scheme
    resources             = each.value.target_resources
  }

  # Link to one or more deduplicated extensions
  dynamic "custom_provider" {
    for_each = length(lookup(each.value, "extension_names", [])) > 0 ? [1] : []
    content {
      authz_extension {
        resources = [
          for ext_name in each.value.extension_names :
          google_network_services_authz_extension.extensions[ext_name].id
        ]
      }
    }
  }

  # Map the complex HTTP rules from your requirement
  dynamic "http_rules" {
    for_each = lookup(each.value, "http_rules", [])
    content {
      from {
        # Optional: Standard sources
        dynamic "sources" {
          for_each = lookup(http_rules.value.from, "sources", [])
          content {
            dynamic "ip_blocks" {
              for_each = lookup(sources.value, "ip_blocks", [])
              content {
                prefix = ip_blocks.value.prefix
                length = ip_blocks.value.length
              }
            }
          }
        }

        # Handle 'not_sources' logic from your example
        dynamic "not_sources" {
          for_each = lookup(http_rules.value.from, "not_sources", [])
          content {
            dynamic "ip_blocks" {
              for_each = lookup(not_sources.value, "ip_blocks", [])
              content {
                prefix = ip_blocks.value.prefix
                length = ip_blocks.value.length
              }
            }
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

      to {
        dynamic "operations" {
          for_each = lookup(http_rules.value.to, "operations", [])
          content {
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