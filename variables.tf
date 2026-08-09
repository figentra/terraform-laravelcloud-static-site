/**
 * @file variables.tf
 * @description Input variables for the laravel-cloud-static-site
 *   module.
 *
 *   Shape mirrors `laravel-cloud-service` where the fields overlap
 *   so operators moving a service between static + full-stack
 *   templates don't relearn the surface. The static-only additions
 *   live under the "Runtime + build" section.
 *
 * Cross-refs:
 *   main.tf                                   resource composition using these inputs
 *   outputs.tf                                values downstream consumers bind
 *   laravel-cloud-service/variables.tf        sibling module with overlapping fields
 */

# ────────────────────────────────────────────────────────────────
# Identity
# ────────────────────────────────────────────────────────────────

variable "name" {
  description = <<-DESC
    Application slug — the Cloud application name + slug source.
    Convention: lowercase-kebab, starts with a letter. Examples:
    `my-dashboard`, `my-landing-page`, `my-docs`.

    Used as the Cloud application name and as the prefix for every
    child environment (`<name>-<env>`).
  DESC
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.name))
    error_message = "name must be lowercase, start with a letter, and contain only letters, digits, and dashes."
  }
}

# ────────────────────────────────────────────────────────────────
# Application (immutable post-create)
# ────────────────────────────────────────────────────────────────

variable "region" {
  description = <<-DESC
    Deploy region. Immutable post-create. Choose the region that
    minimizes latency to the SPA's target users; a single region
    usually suffices because the built bundle is served from Cloud's
    CDN.

    Example: `us-east-1`, `eu-west-1`.
  DESC
  type        = string
  default     = "us-east-1"
}

variable "source_control_provider_type" {
  description = <<-DESC
    Source control provider — one of `github`, `gitlab`, `bitbucket`.
    Immutable post-create.
  DESC
  type        = string
  default     = "gitlab"

  validation {
    condition     = contains(["github", "gitlab", "bitbucket"], var.source_control_provider_type)
    error_message = "source_control_provider_type must be one of: github, gitlab, bitbucket."
  }
}

variable "repository" {
  description = <<-DESC
    Repository identifier in `owner/repo` shape (e.g.
    `my-org/frontend-spa`). REQUIRED — Cloud API v2 rejects apps
    without one.
  DESC
  type        = string
}

variable "root_directory" {
  description = <<-DESC
    Sub-path within the repo Cloud builds from. Empty / null when
    building from the repo root. Required for monorepos where one
    repo hosts multiple Cloud applications at different sub-paths
    (e.g. `apps/dashboard`, `apps/landing-page`).
  DESC
  type        = string
  default     = null
}

variable "slack_channel" {
  description = <<-DESC
    Slack channel for deploy notifications. Cloud rejects
    `#channel-name`; supply Slack channel ID or null to skip.
  DESC
  type        = string
  default     = null
}

variable "cluster_id" {
  description = <<-DESC
    Deploy cluster ID. Optional — Cloud picks a default when unset.
    Consumers set this when the workspace uses a dedicated cluster
    for isolation.
  DESC
  type        = string
  default     = null
}

# ────────────────────────────────────────────────────────────────
# Runtime + build (SPA-flavour defaults)
# ────────────────────────────────────────────────────────────────

variable "default_node_version" {
  description = <<-DESC
    Node.js version used for the build step. Cloud supports 20 /
    22 / 24. Every env inherits this unless overridden via
    `environments[<env>].node_version`.
  DESC
  type        = string
  default     = "24"

  validation {
    condition     = contains(["20", "22", "24"], var.default_node_version)
    error_message = "default_node_version must be one of: 20, 22, 24."
  }
}

variable "default_build_command" {
  description = <<-DESC
    Build command executed on each deploy. Cloud's textarea shape —
    single string with `\n` separating multi-line commands. Default
    is the Vite/pnpm-friendly `npm ci --audit false\nnpm run build`.

    Callers with a different toolchain (pnpm, bun, deno) override
    per invocation OR per env via
    `environments[<env>].build_command`.
  DESC
  type        = string
  default     = "npm ci --audit false\nnpm run build"
}

variable "default_deploy_command" {
  description = <<-DESC
    Post-deploy command. Empty for static sites — no migrations to
    run, no artisan commands to fire. Cloud accepts an empty string.
    Override per env when a specific SPA needs a post-build hook
    (e.g. purging a CDN cache).
  DESC
  type        = string
  default     = ""
}

variable "enable_deploy_hook" {
  description = <<-DESC
    When true, exposes a deploy-hook webhook URL for external CI
    systems to trigger deploys. Default `false` — push-to-deploy is
    on by default and covers the workspace-canonical CI shape.
  DESC
  type        = bool
  default     = false
}

variable "enable_hibernation" {
  description = <<-DESC
    When true, envs hibernate after inactivity + wake on inbound
    traffic. Trades cold-start latency for zero idle cost. Default
    `true` for dev + stg (cost saver); consumers typically flip
    this to `false` on prd (always warm for real users) via
    `environments["prd"].uses_hibernation = false`.
  DESC
  type        = bool
  default     = true
}

# ────────────────────────────────────────────────────────────────
# Per-environment configuration
# ────────────────────────────────────────────────────────────────

variable "environments" {
  description = <<-DESC
    Per-environment configuration. Keys: env slug (`dev`/`stg`/`prd`).
    Values: env-specific config translated to
    `laravelcloud_environment` fields.

    All override fields fall back to the module-level defaults when
    unset. Only `branch` is required; everything else optional.

    v0.4.5 addition: `color` — one of `blue`/`green`/`orange`/
    `purple`/`red`/`yellow`/`cyan`/`gray`. Falls back to
    `var.default_env_colors[<env>]`.

    Example:
      environments = {
        dev = { branch = "develop", variables = { VITE_APP_ENV = "development" } }
        prd = { branch = "main",    variables = { VITE_APP_ENV = "production" }, uses_hibernation = false }
      }
  DESC
  type = map(object({
    branch              = string
    variables           = optional(map(string), {})
    node_version        = optional(string)
    build_command       = optional(string)
    deploy_command      = optional(string)
    uses_push_to_deploy = optional(bool)
    uses_deploy_hook    = optional(bool)
    uses_hibernation    = optional(bool)
    color               = optional(string)
  }))
  default = {}
}

variable "default_env_colors" {
  description = <<-DESC
    Default color per env slug. Matches the workspace convention
    (`dev=green` for OK, `stg=orange` for care, `prd=red` for
    danger, `preview=purple` for experimental). Callers override
    individual envs via `environments[<env>].color`.
  DESC
  type        = map(string)
  default = {
    dev = "green"
    stg = "orange"
    prd = "red"
  }
}

# ────────────────────────────────────────────────────────────────
# Domains
# ────────────────────────────────────────────────────────────────

variable "domains" {
  description = <<-DESC
    Custom domains bound to this SPA's environments. Map shape:
    `{ <env> = "<hostname>" }`.

    Example:
      domains = {
        dev = "app.dev.example.com"
        prd = "app.example.com"
      }
  DESC
  type        = map(string)
  default     = {}
}

variable "domain_defaults" {
  description = <<-DESC
    Domain-binding defaults. Same shape as
    `laravel-cloud-service.domain_defaults` so operators moving
    between the two modules use identical inputs.

    Valid values per the Cloud SDK's DomainRedirect /
    DomainVerificationMethod / DomainCloudflareStrategy enums:
      www_redirect        : "root_to_www" | "www_to_root"
      verification_method : "pre_verification" | "real_time"
      cloudflare_strategy : "none" | "dns" | "dns_proxy"
  DESC
  type = object({
    www_redirect        = optional(string, "www_to_root")
    verification_method = optional(string, "real_time")
    cloudflare_strategy = optional(string, "dns_proxy")
  })
  default = {}
}

variable "tags" {
  description = <<-DESC
    Free-form tags for cost attribution + audit. Informational only
    — Cloud API v2 doesn't expose a tags field yet. Consumers still
    author the map so the intent survives when the API gains
    support.
  DESC
  type        = map(string)
  default     = {}
}
