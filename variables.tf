# Input variables for the laravel-cloud-static-site module.
#
# Shape mirrors `laravel-cloud-service` where the fields overlap so
# operators moving a service between static + full-stack templates
# don't relearn the surface. The static-only additions live under the
# "Runtime + build" section.

# ────────────────────────────────────────────────────────────────
# Identity
# ────────────────────────────────────────────────────────────────

variable "name" {
  description = "Application slug — the Cloud application name + slug source."
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
  description = "Deploy region. Immutable post-create."
  type        = string
  default     = "us-east-1"
}

variable "source_control_provider_type" {
  description = "Source control provider — one of github, gitlab, bitbucket. Immutable post-create."
  type        = string
  default     = "gitlab"

  validation {
    condition     = contains(["github", "gitlab", "bitbucket"], var.source_control_provider_type)
    error_message = "source_control_provider_type must be one of: github, gitlab, bitbucket."
  }
}

variable "repository" {
  description = "Repository identifier in `owner/repo` shape. REQUIRED."
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
  description = "Slack channel for deploy notifications. Cloud rejects `#channel-name`; use Slack channel ID or null."
  type        = string
  default     = null
}

variable "cluster_id" {
  description = "Deploy cluster ID. Optional — Cloud picks a default when unset."
  type        = string
  default     = null
}

# ────────────────────────────────────────────────────────────────
# Runtime + build (SPA-flavour defaults)
# ────────────────────────────────────────────────────────────────

variable "default_node_version" {
  description = "Node.js version used for the build step. Cloud supports 20 / 22 / 24."
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
    single string with `\n` separating multi-line commands. Default is
    the Vite/pnpm-friendly `npm ci --audit false\nnpm run build`.
    Callers with a different toolchain (pnpm, bun, deno) override per
    invocation OR per env.
  DESC
  type        = string
  default     = "npm ci --audit false\nnpm run build"
}

variable "default_deploy_command" {
  description = <<-DESC
    Post-deploy command. Empty for static sites — no migrations to run,
    no artisan commands to fire. Cloud accepts an empty string.
  DESC
  type        = string
  default     = ""
}

variable "enable_deploy_hook" {
  description = "When true, exposes a deploy-hook webhook URL for external CI systems to trigger deploys. Default off — push-to-deploy is on by default."
  type        = bool
  default     = false
}

variable "enable_hibernation" {
  description = <<-DESC
    When true, envs hibernate after inactivity + wake on inbound
    traffic. Trades cold-start latency for zero idle cost. Default on
    for dev + stg (cost saver); off on prd (always warm for real users).
    Callers override per env via environments[<env>].uses_hibernation.
  DESC
  type        = bool
  default     = true
}

# ────────────────────────────────────────────────────────────────
# Per-environment configuration
# ────────────────────────────────────────────────────────────────

variable "environments" {
  description = <<-DESC
    Per-environment configuration. Keys: env slug (dev/stg/prd).
    Values: env-specific config translated to laravelcloud_environment
    fields.

    All override fields fall back to the module-level defaults when
    unset. Only `branch` is required; everything else optional.

    v0.4.5 addition: `color` — one of blue/green/orange/purple/red/
    yellow/cyan/gray. Falls back to var.default_env_colors[<env>].
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
    (dev=green for OK, stg=orange for care, prd=red for danger,
    preview=purple for experimental). Callers override individual
    envs via environments[<env>].color.
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
  description = "Custom domains bound to this SPA's environments. Map shape: { <env> = \"<hostname>\" }."
  type        = map(string)
  default     = {}
}

variable "domain_defaults" {
  description = "Domain-binding defaults. Same shape as laravel-cloud-service."
  type = object({
    www_redirect        = optional(string, "www_to_root")
    verification_method = optional(string, "real_time")
    cloudflare_strategy = optional(string, "dns_proxy")
  })
  default = {}
}

variable "tags" {
  description = "Free-form tags for cost attribution + audit. Informational only — Cloud API v2 doesn't expose a tags field yet."
  type        = map(string)
  default     = {}
}
