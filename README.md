# terraform-google-policy-authz-extension

## Description
### Tagline
This is an auto-generated module.

### Detailed
This module was generated from [terraform-google-module-template](https://github.com/terraform-google-modules/terraform-google-module-template/), which by default generates a module that simply creates a GCS bucket. As the module develops, this README should be updated.

The resources/services/activations/deletions that this module will create/trigger are:

- Create a GCS bucket with the provided name

### PreDeploy
To deploy this blueprint you must have an active billing account and billing permissions.

## Architecture
![alt text for diagram](https://www.link-to-architecture-diagram.com)
1. Architecture description step no. 1
2. Architecture description step no. 2
3. Architecture description step no. N

## Documentation
- [Hosting a Static Website](https://cloud.google.com/storage/docs/hosting-static-website)

## Deployment Duration
Configuration: X mins
Deployment: Y mins

## Cost
[Blueprint cost details](https://cloud.google.com/products/calculator?id=02fb0c45-cc29-4567-8cc6-f72ac9024add)

## Usage

Basic usage of this module is as follows:

```hcl
module "policy_authz_extension" {
  source  = "terraform-google-modules/policy-authz-extension/google"
  version = "~> 0.1"

  project_id  = "<PROJECT ID>"
  bucket_name = "gcs-test-bucket"
}
```

Functional examples are included in the
[examples](./examples/) directory.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| extensions\_config | A map of unique Authz Extensions. | <pre>map(object({<br>    description           = optional(string, "Managed by ADC")<br>    load_balancing_scheme = string # e.g., "INTERNAL_MANAGED"<br>    authority             = string<br>    backend_service       = string<br>    timeout               = optional(string, "0.1s")<br>    fail_open             = optional(bool, false)<br>    forward_headers       = optional(list(string), [])<br>  }))</pre> | `{}` | no |
| location | The GCP region for the security resources. | `string` | n/a | yes |
| policies\_config | A map of Authz Policies. | <pre>map(object({<br>    description           = optional(string, "Security policy for Agent Gateway")<br>    action                = string # ALLOW, DENY, CUSTOM<br>    target_resources      = list(string)<br>    load_balancing_scheme = string<br>    extension_names       = optional(list(string), [])<br>    <br>    # Structured HTTP Rules<br>    http_rules = optional(list(object({<br>      from = optional(object({<br>        sources = optional(list(object({<br>          ip_blocks = optional(list(object({<br>            prefix = string<br>            length = number<br>          })), [])<br>          principals = optional(list(any), [])<br>        })), [])<br>        not_sources = optional(list(object({<br>          ip_blocks = optional(list(object({<br>            prefix = string<br>            length = number<br>          })), [])<br>          principals = optional(list(any), [])<br>        })), [])<br>      }))<br>      to = optional(object({<br>        operations = optional(list(object({<br>          paths      = optional(list(any), [])<br>          methods    = optional(list(string), [])<br>          header_set = optional(list(any), [])<br>        })), [])<br>      }))<br>      when = optional(string) # CEL Expression<br>    })), [])<br>  }))</pre> | `{}` | no |
| project\_id | The ID of the project where resources will be created. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| extension\_ids | Map of extension names to their unique resource IDs. |
| policy\_extension\_map | A mapping showing the list of extension IDs associated with each policy name. |
| policy\_ids | Map of policy names to their unique resource IDs. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

These sections describe requirements for using this module.

### Software

The following dependencies must be available:

- [Terraform][terraform] v0.13
- [Terraform Provider for GCP][terraform-provider-gcp] plugin v3.0

### Service Account

A service account with the following roles must be used to provision
the resources of this module:

- Storage Admin: `roles/storage.admin`

The [Project Factory module][project-factory-module] and the
[IAM module][iam-module] may be used in combination to provision a
service account with the necessary roles applied.

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- Google Cloud Storage JSON API: `storage-api.googleapis.com`

The [Project Factory module][project-factory-module] can be used to
provision a project with the necessary APIs enabled.

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

[iam-module]: https://registry.terraform.io/modules/terraform-google-modules/iam/google
[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html

## Security Disclosures

Please see our [security disclosure process](./SECURITY.md).
