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
  description = "A map of unique Authz Extensions."
  type = map(object({
    description           = optional(string, "Managed by ADC")
    load_balancing_scheme = string # e.g., "INTERNAL_MANAGED"
    authority             = string
    backend_service       = string
    timeout               = optional(string, "0.1s")
    fail_open             = optional(bool, false)
    forward_headers       = optional(list(string), [])
  }))
  default = {}
}

variable "policies_config" {
  description = "A map of Authz Policies."
  type = map(object({
    description           = optional(string, "Managed by ADC")
    action                = string # ALLOW, DENY, CUSTOM
    target_resources      = list(string) # URIs of Forwarding Rules
    load_balancing_scheme = string
    extension_names       = optional(list(string), []) # Keys from extensions_config
    
    # Structure for simplified HTTP Rules
    http_rules = optional(list(any), []) 
  }))
  default = {}
}