# Outputs — the surface consuming HCL references.

output "application_id" {
  description = "Cloud-assigned application ID."
  value       = laravelcloud_application.this.id
}

output "application_slug" {
  description = "URL-safe slug derived from name by Cloud."
  value       = laravelcloud_application.this.slug
}

output "application_name" {
  description = "Human-readable name — matches var.name."
  value       = laravelcloud_application.this.name
}

output "region" {
  description = "Deploy region — matches var.region."
  value       = laravelcloud_application.this.region
}

output "environment_ids" {
  description = "Map of env slug → environment ID."
  value       = { for k, v in laravelcloud_environment.envs : k => v.id }
}

output "vanity_domains" {
  description = "Map of env slug → Cloud-assigned *.laravel.cloud hostname."
  value       = { for k, v in laravelcloud_environment.envs : k => v.vanity_domain }
}

output "domain_ids" {
  description = "Map of env slug → custom domain binding ID."
  value       = { for k, v in laravelcloud_domain.domains : k => v.id }
}
