# scafctl-solution-plugin-template

[![CI](https://github.com/oakwood-commons/scafctl-solution-plugin-template/actions/workflows/ci.yml/badge.svg)](https://github.com/oakwood-commons/scafctl-solution-plugin-template/actions/workflows/ci.yml)
![scafctl >= 0.35.0](https://img.shields.io/badge/scafctl-%3E%3D%200.35.0-blue)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Scaffolds a complete scafctl plugin project (provider or auth-handler) with source
code, tests, build config, CI/CD pipelines, GitHub repo configuration, and Copilot
AI instructions.

## Prerequisites

- [scafctl CLI](https://github.com/oakwood-commons/scafctl/releases) >= 0.35.0
- Go 1.26+ (only needed if running locally without `create_repo=true`)
- [gh CLI](https://cli.github.com/) (only needed if using `create_repo=true`)

## Quick Start

### From the registry (recommended)

**Bash:**

```bash
scafctl run ghcr.io/oakwood-commons/solutions/plugin-template \
  -r name=scafctl-plugin-myecho \
  -r module=github.com/myorg/scafctl-plugin-myecho \
  -r description="Echoes input values" \
  -r plugin_type=provider \
  -r capabilities=from,transform
```

**PowerShell:**

```powershell
scafctl run ghcr.io/oakwood-commons/solutions/plugin-template `
    -r name=scafctl-plugin-myecho `
    -r module=github.com/myorg/scafctl-plugin-myecho `
    -r 'description=Echoes input values' `
    -r plugin_type=provider `
    -r capabilities=from,transform
```

### From a local clone

**Bash:**

```bash
git clone https://github.com/oakwood-commons/scafctl-solution-plugin-template.git
cd scafctl-solution-plugin-template

scafctl run solution -f scafctl/solution.yaml \
  -r name=scafctl-plugin-myecho \
  -r module=github.com/myorg/scafctl-plugin-myecho \
  -r description="Echoes input values" \
  -r plugin_type=provider \
  -r capabilities=from,transform
```

**PowerShell:**

```powershell
git clone https://github.com/oakwood-commons/scafctl-solution-plugin-template.git
cd scafctl-solution-plugin-template

scafctl run solution -f scafctl/solution.yaml `
    -r name=scafctl-plugin-myecho `
    -r module=github.com/myorg/scafctl-plugin-myecho `
    -r 'description=Echoes input values' `
    -r plugin_type=provider `
    -r capabilities=from,transform
```

### With GitHub repo creation

**Bash:**

```bash
scafctl run solution -f scafctl/solution.yaml \
  -r name=scafctl-plugin-myecho \
  -r module=github.com/myorg/scafctl-plugin-myecho \
  -r description="Echoes input values" \
  -r plugin_type=provider \
  -r capabilities=from,transform \
  -r create_repo=true \
  -r repo_visibility=public
```

**PowerShell:**

```powershell
scafctl run solution -f scafctl/solution.yaml `
    -r name=scafctl-plugin-myecho `
    -r module=github.com/myorg/scafctl-plugin-myecho `
    -r 'description=Echoes input values' `
    -r plugin_type=provider `
    -r capabilities=from,transform `
    -r create_repo=true `
    -r repo_visibility=public
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `name` | Yes | -- | Plugin name (3-60 chars, lowercase with hyphens). Convention: `scafctl-plugin-<name>` |
| `module` | Yes | -- | Go module path (e.g., `github.com/myorg/scafctl-plugin-echo`) |
| `description` | Yes | -- | Brief description of what the plugin does |
| `plugin_type` | No | `provider` | Plugin type: `provider` or `auth-handler` |
| `capabilities` | No | `from` | Comma-separated capabilities: `from`, `transform`, `action`, `validation` |
| `create_repo` | No | `false` | Create a GitHub repository and push initial commit |
| `repo_visibility` | No | `public` | GitHub repo visibility: `public` or `private` |

## Generated Project Structure

### Provider plugin

```
scafctl-plugin-myecho/
  .github/
    workflows/ci.yaml, release.yaml, dco.yaml, codeql.yaml
    CODEOWNERS, SECURITY.md, dependabot.yml, copilot-instructions.md
    ISSUE_TEMPLATE/bug_report.md, feature_request.md
    instructions/go-conventions.instructions.md, go-testing.instructions.md
    PULL_REQUEST_TEMPLATE.md
  cmd/scafctl-plugin-myecho/main.go
  internal/myecho/provider.go
  internal/myecho/provider_test.go
  .gitignore, .golangci.yml, .goreleaser.yaml
  CODE_OF_CONDUCT.md, CONTRIBUTING.md, LICENSE, README.md
  Taskfile.yaml, codecov.yml, go.mod
```

### Auth-handler plugin

Same structure but with `auth_handler.go` / `auth_handler_test.go` instead of
`provider.go` / `provider_test.go`.

## Features

- **Provider and auth-handler** plugin types
- **Complete GitHub Actions CI/CD** (test, lint, release with goreleaser)
- **Branch and tag protection** rulesets (when `create_repo=true`)
- **Dependabot** for dependency updates
- **CodeQL** for security scanning
- **DCO enforcement** on all commits
- **goreleaser** multi-platform builds with cosign signing
- **Copilot AI instructions** for development assistance
- **Issue and PR templates**
- **Codecov** integration

## Versioning

This solution follows semver:

- **Major**: Breaking template changes (generated output structure differs)
- **Minor**: New template files or features
- **Patch**: Bug fixes and typo corrections

## Development

```bash
task lint       # Lint the solution YAML
task test       # Run functional tests (CEL assertions against resolver outputs)
task validate   # Render and verify generated Go project compiles
task ci         # Full pipeline: lint + test + validate
```

## Publishing

```bash
task publish VERSION=1.0.0
task sign VERSION=1.0.0
```

## Examples

See the [examples/](examples/) directory for invocation scripts (bash and PowerShell):

| Scenario | Bash | PowerShell |
|----------|------|------------|
| Minimal provider plugin | `provider-basic.sh` | `provider-basic.ps1` |
| Provider with all capabilities | `provider-multi-cap.sh` | `provider-multi-cap.ps1` |
| Auth-handler plugin | `auth-handler.sh` | `auth-handler.ps1` |
| Full repo creation flow | `with-github-repo.sh` | `with-github-repo.ps1` |

## Links

- [scafctl](https://github.com/oakwood-commons/scafctl) -- Main CLI tool
- [Plugin SDK](https://github.com/oakwood-commons/scafctl-plugin-sdk) -- SDK for plugin development
- [Provider Authoring Guide](https://github.com/oakwood-commons/scafctl/blob/main/docs/tutorials/plugin-development.md)

## License

[Apache License 2.0](LICENSE)
