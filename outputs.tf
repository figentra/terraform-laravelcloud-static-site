/**
 * @file outputs.tf
 * @description Outputs the laravel-cloud-static-site module
 *   publishes. Env roots typically bind `vanity_domains` into
 *   Cloudflare CNAME records that map custom hostnames to Cloud's
 *   default `<slug>.laravel.cloud` endpoint.
 *
 * Cross-refs:
 *   main.tf                             resources this file exposes
 *   variables.tf                        inputs shaping the outputs
 *   cloudflare-record/variables.tf      sibling — `content` receives vanity_domains
 */

output "application_id" {
  description = <<-DESC
    Cloud-assigned application ID (opaque). Consumers reference the
    ID from adjacent resources (audit logs, observability wiring)
    that don't need the human-readable slug.
  DESC
  value       = laravelcloud_application.this.id
}

output "application_slug" {
  description = <<-DESC
    URL-safe slug derived from `var.name` by Cloud. Used to build
    `<slug>.laravel.cloud` endpoints. Consumers reference this from
    Cloudflare CNAME record `content` values.
  DESC
  value       = laravelcloud_application.this.slug
}

output "application_name" {
  description = <<-DESC
    Human-readable name — passthrough of `var.name`. Reviewers use
    this in deploy logs.
  DESC
  value       = laravelcloud_application.this.name
}

output "region" {
  description = <<-DESC
    Deploy region — passthrough of `var.region`. Consumers may
    reference it when composing region-specific companion resources.
  DESC
  value       = laravelcloud_application.this.region
}

output "environment_ids" {
  description = <<-DESC
    Map of `env slug → environment ID`. Consumers use these IDs
    when configuring adjacent per-env resources (e.g. observability
    labels keyed by env).
  DESC
  value       = { for k, v in laravelcloud_environment.envs : k => v.id }
}

output "vanity_domains" {
  description = <<-DESC
    Map of `env slug → Cloud-assigned <slug>-<env>.laravel.cloud
    hostname`. The env root binds these as the `content` of the
    Cloudflare CNAME records that expose the SPA at custom
    hostnames.

    Example downstream binding:
      module.dashboard_dev_cname.content = module.dashboard.vanity_domains["dev"]
  DESC
  value       = { for k, v in laravelcloud_environment.envs : k => v.vanity_domain }
}

output "domain_ids" {
  description = <<-DESC
    Map of `env slug → custom domain binding ID`. Consumers use
    these when tracing a specific custom-domain binding through
    Cloud's audit logs.
  DESC
  value       = { for k, v in laravelcloud_domain.domains : k => v.id }
}
