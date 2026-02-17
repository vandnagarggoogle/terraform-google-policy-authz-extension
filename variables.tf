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
  }))
}

variable "policies_config" {
  description = "List of security rules. Each can link to ONE extension or IAP."
  type = list(object({
    name                  = string
    action                = string # ALLOW, DENY, CUSTOM
    load_balancing_scheme = string
    target_resources      = list(string)
    description           = optional(string, "Security policy for Agent Gateway")
    
    extension_name        = optional(string) 
    
    iap_enabled           = optional(bool, false)

    http_rules = optional(list(object({
      when = optional(string)
      from = optional(object({
        not_sources = optional(list(object({
          ip_blocks = optional(list(object({
            prefix = string
            length = number
          })), [])
        })), [])
      }))
      to = optional(object({
        operations = optional(list(object({
          paths = optional(list(object({ exact = string })), [])
        })), [])
      }))
    })), [])
  }))
}
