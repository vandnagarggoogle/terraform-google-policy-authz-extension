variable "project_id" {
  type = string
}

variable "location" {
  type = string
}

variable "extensions_config" {
  description = "List of unique security logic modules."
  type = list(object({
    name                  = string
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
  description = "A list of Authz Policies with structured HTTP rules."
  type = list(object({
    name                  = string
    action                = string
    load_balancing_scheme = string
    target_resources      = list(string)
    description           = optional(string, "Managed by ADC")
    extension_names       = optional(list(string), [])
    iap_enabled           = optional(bool,false)
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
          methods = optional(list(string), [])
          paths   = optional(list(object({ exact = string })), [])
          header_set = optional(list(object({
            headers = optional(list(object({
              name = string
              value = optional(object({
                exact       = string
                ignore_case = optional(bool, true)
              }))
            })), [])
          })), [])
        })), [])
      }))
    })), [])
  }))
}

