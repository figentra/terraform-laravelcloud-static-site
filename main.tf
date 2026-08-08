# laravel-cloud-static-site module — deploys a Vite SPA / static site
# onto Laravel Cloud in one HCL block.
#
# ────────────────────────────────────────────────────────────────
# Contract
#
# The workspace's Vite SPAs (figentra-landing, academorix-dashboard,
# academorix-landing) deploy via Laravel Cloud alongside the backend
# services rather than via Cloudflare Pages / Vercel / Netlify. Cloud
# supports Node.js 20/22/24 build environments + serves the built
# `dist/` bundle from an ephemeral filesystem.
#
# What this module creates (Cloud API v2 aligned + provider v0.4.4):
#   - Application (top-level Cloud unit)
#   - N environments (dev / stg / prd) with:
#       - Node runtime pinned via `node_version` (default 24)
#       - `build_command` set to `npm ci --audit false && npm run build`
#         (multi-line via \n) by default; overrideable per invocation
#       - `deploy_command` empty (static sites have no post-build step)
#       - `uses_octane` false, `uses_hibernation` env-controlled
#       - Env vars from environments[<env>].variables
#   - Optional custom domains via var.domains
#
# What this module DOES NOT create:
#   - Database schemas (SPAs don't use them)
#   - Cache instances (SPAs don't use them)
#   - WebSocket apps (SPAs don't use them)
#   - Buckets (SPAs load static assets from Cloud's CDN)
#
# For the full-stack backend service shape (DB + cache + WS + buckets),
# use `../laravel-cloud-service` instead.
#
# ────────────────────────────────────────────────────────────────
# Provider version
#
# This module requires provider v0.4.4+ for the `build_command` /
# `deploy_command` / `node_version` / `uses_*` fields on
# `laravelcloud_environment`. Callers use the dev-override binary
# during Wave 8-C authoring; the registry version bumps to 0.4.4
# after the SPAs prove out in every env.

# ────────────────────────────────────────────────────────────────
# Application — the top-level Cloud unit.
# ────────────────────────────────────────────────────────────────

resource "laravelcloud_application" "this" {
  name                         = var.name
  region                       = var.region
  source_control_provider_type = var.source_control_provider_type
  repository                   = var.repository
  slack_channel                = var.slack_channel
  cluster_id                   = var.cluster_id
}

# ────────────────────────────────────────────────────────────────
# Environments — one per entry in var.environments.
#
# Every SPA env sets:
#   - Node version (default 24) — Cloud auto-detects the build kind
#   - Build command — `npm ci --audit false\nnpm run build` by default
#   - Deploy command — empty
#   - Push-to-deploy on (Cloud auto-deploys on branch push)
#   - Deploy hook off (turn on via var.enable_deploy_hook)
#   - Octane off (irrelevant for static sites)
#   - Hibernation controlled by var.enable_hibernation (default true —
#     saves cost when the SPA isn't hit for a while)
#
# Callers override any of the above per env via environments[<env>].*.
# ────────────────────────────────────────────────────────────────

resource "laravelcloud_environment" "envs" {
  for_each = var.environments

  application_id = laravelcloud_application.this.id
  name           = each.key
  branch         = each.value.branch
  variables      = each.value.variables

  # Runtime + deploy scripts — SPA-flavoured defaults, per-env override.
  #
  # Use a null-check ternary instead of coalesce() — coalesce() rejects
  # empty strings, but deploy_command legitimately IS an empty string
  # by default for static sites. Consistent null-check across every
  # optional so the module reads uniformly.
  node_version   = each.value.node_version == null ? var.default_node_version : each.value.node_version
  build_command  = each.value.build_command == null ? var.default_build_command : each.value.build_command
  deploy_command = each.value.deploy_command == null ? var.default_deploy_command : each.value.deploy_command

  # Deploy toggles. `!= null ? x : y` on bools so `false` overrides
  # don't get coerced to the fallback (coalesce would drop `false`).
  uses_push_to_deploy = each.value.uses_push_to_deploy != null ? each.value.uses_push_to_deploy : true
  uses_deploy_hook    = each.value.uses_deploy_hook != null ? each.value.uses_deploy_hook : var.enable_deploy_hook
  uses_octane         = false
  uses_hibernation    = each.value.uses_hibernation != null ? each.value.uses_hibernation : var.enable_hibernation

  # Env color — visual identifier in the Cloud dashboard.
  # Per-env override wins over module default (dev=green, stg=orange,
  # prd=red per the workspace convention).
  color = each.value.color != null ? each.value.color : lookup(var.default_env_colors, each.key, null)
}

# ────────────────────────────────────────────────────────────────
# Domains — one per (env, hostname) pair in var.domains.
# ────────────────────────────────────────────────────────────────

resource "laravelcloud_domain" "domains" {
  for_each = var.domains

  environment_id      = laravelcloud_environment.envs[each.key].id
  name                = each.value
  www_redirect        = var.domain_defaults.www_redirect
  verification_method = var.domain_defaults.verification_method
  cloudflare_strategy = var.domain_defaults.cloudflare_strategy
}
