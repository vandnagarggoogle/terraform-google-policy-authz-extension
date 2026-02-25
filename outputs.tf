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

output "extension_ids" {
  description = "Map of extension names to their unique resource IDs."
  value       = { for k, v in google_network_services_authz_extension.extension : k => v.id }
}

output "policy_ids" {
  description = "Map of policy names to their unique resource IDs."
  value       = { for k, v in google_network_security_authz_policy.policy : k => v.id }
}

output "policy_extension_map" {
  description = "Maps each policy name to its assigned extension IDs (if CUSTOM action)."
  value       = { 
    for k, v in var.policies_config : k => v.extension_names if v.action == "CUSTOM" && !v.iap_enabled 
  }
}
