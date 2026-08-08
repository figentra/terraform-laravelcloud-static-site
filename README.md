# laravel-cloud-static-site module

Deploys a Vite SPA / static site onto Laravel Cloud in one HCL block.

## Purpose

The workspace's public frontend surfaces (`figentra-landing`,
`academorix-dashboard`, `academorix-landing`) build via `npm run build`
and serve their `dist/` bundle from Cloud's CDN. They don't need the
DB + cache + WS + buckets the backend services carry — this module is
the lightweight version.

## Contract

Creates:

- **Application** — the top-level Cloud unit (name + slug + region +
  repository + slack channel + cluster).
- **Environment(s)** — one per entry in `var.environments`. Each env
  carries a runtime version (`node_version`), a build command
  (`build_command`), a deploy command (`deploy_command`), and the
  standard four toggles (`uses_push_to_deploy`, `uses_deploy_hook`,
  `uses_octane`, `uses_hibernation`).
- **Domain(s)** — optional custom domain bindings per env.

Does NOT create:

- Database schemas, cache instances, WebSocket apps, buckets.
  For those, use `../laravel-cloud-service`.

## Usage

```hcl
module "landing" {
  source = "../../modules/laravel-cloud-static-site"

  name                         = "figentra-landing"
  region                       = "us-east-1"
  source_control_provider_type = "gitlab"
  repository                   = "figentra-inc/frontend/landing"

  environments = {
    dev = {
      branch = "develop"
      variables = {
        NODE_ENV      = "development"
        VITE_API_URL  = "https://api.dev.figentra.com"
      }
    }
  }

  domains = {
    dev = "dev.figentra.com"
  }

  tags = local.common_tags
}
```

## Defaults

| Field | Default |
|---|---|
| `node_version` | `24` |
| `build_command` | `npm ci --audit false\nnpm run build` |
| `deploy_command` | `""` (empty) |
| `uses_push_to_deploy` | `true` |
| `uses_deploy_hook` | `false` |
| `uses_octane` | `false` (forced — irrelevant for static) |
| `uses_hibernation` | `true` (cost saver — override to `false` on prd) |

## Provider version

Requires provider **v0.4.4+**. Older versions lack the
`build_command` / `deploy_command` / `node_version` / `uses_*`
fields on `laravelcloud_environment`.

## Cross-references

- Sibling: [`laravel-cloud-service`](../laravel-cloud-service) — full-stack
  backend module with DB + cache + WS + buckets.
- [Cloud docs — environments](https://cloud.laravel.com/docs/environments)
- [Provider docs](../../provider-laravel-cloud/README.md)
- [`.kiro/steering/laravel-cloud-conventions.md`](../../../.kiro/steering/laravel-cloud-conventions.md)
