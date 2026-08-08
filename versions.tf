# Terraform + provider version constraints for the
# laravel-cloud-static-site module.
#
# Requires provider v0.4.4+ for the build/deploy scripts + node_version
# + uses_* toggles on laravelcloud_environment.

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    laravelcloud = {
      source  = "figentra/laravel-cloud"
      version = "~> 0.4"
    }
  }
}
