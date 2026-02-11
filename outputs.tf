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
  value       = { for k, v in google_network_services_authz_extension.extensions : k => v.id }
}

output "policy_ids" {
  description = "Map of policy names to their unique resource IDs."
  value       = { for k, v in google_network_security_authz_policy.policies : k => v.id }
}

output "policy_extension_map" {
  description = "A mapping showing the list of extension IDs associated with each policy name."
  value = {
    for name, policy in google_network_security_authz_policy.policies :
    name => try(policy.custom_provider[0].authz_extension[0].resources, [])
  }
}
