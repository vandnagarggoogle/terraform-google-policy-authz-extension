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

variable "project_id" {
  description = "The ID of the project where resources will be created."
  type        = string
}

variable "location" {
  description = "The GCP region for the security resources."
  type        = string
}

variable "extensions_config" {
  description = "A list of unique Authz Extensions."
  type = list(object({
    name                  = string # Unique ID for the extension
    authority             = string
    backend_service       = string
    load_balancing_scheme = string
    description           = optional(string, "Managed by ADC")
    timeout               = optional(string, "0.1s")
    fail_open             = optional(bool, false)
    forward_headers       = optional(list(string), [])
  }))
}


variable "policies_config" {
  description = "List of Authz Policies with structured rules."
  type = list(object({
    name                  = string # The unique identifier for the policy
    action                = string
    load_balancing_scheme = string
    target_resources      = list(string)
    description           = optional(string, "Managed by ADC")
    extension_names       = optional(list(string), [])
    http_rules = optional(list(object({
      when = optional(string)
      from = optional(object({
        not_sources = optional(list(object({
          ip_blocks = optional(list(object({
            prefix = string
            length = number
          })), [])
          principals = optional(list(object({
            principal_selector = optional(string, "CLIENT_CERT_URI_SAN")
            principal = optional(object({
              exact       = optional(string)
              ignore_case = optional(bool, true)
            }))
          })), [])
        })), [])
      }))
      to = optional(object({
        operations = optional(list(object({
          paths = optional(list(object({
            exact = string
          })), [])
          methods = optional(list(string), [])
          header_set = optional(list(object({
            headers = optional(list(object({
              name = string
              value = object({
                exact       = string
                ignore_case = optional(bool, true)
              })
            })), [])
          })), [])
        })), [])
      }))
    })), [])
  }))
}
