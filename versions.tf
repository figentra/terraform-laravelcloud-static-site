/**
 * @file versions.tf
 * @description Terraform + provider version constraints for the
 *   laravel-cloud-static-site module.
 *
 *   Requires provider v0.4.4+ for the build/deploy scripts +
 *   node_version + uses_* toggles on `laravelcloud_environment`.
 *   Pin matches the sibling `laravel-cloud-service` module.
 *
 * Cross-refs:
 *   main.tf                              provider consumer
 *   laravel-cloud-service/versions.tf    sibling — same pin
 */

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    laravelcloud = {
      source  = "figentra/laravel-cloud"
      version = "~> 0.3"
    }
  }
}
