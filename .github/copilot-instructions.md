# scafctl-solution-plugin-template - AI Agent Instructions

## Overview

This repository contains a scafctl solution that scaffolds complete plugin projects
(provider or auth-handler) for the scafctl ecosystem.

## Key Facts

- **No Go code**: This repo contains only YAML and Go template files
- **Testing**: Use `scafctl lint` and `scafctl test functional` -- NOT Go test commands
- **Templates**: Use `<%` / `%>` delimiters to avoid conflicts with generated `{{`/`}}` content
- **Placeholders**: `PLUGIN_NAME` and `PKG_NAME` in file paths are replaced at render time

## Build & Test Commands

```bash
task lint       # Lint solution YAML
task test       # Run functional tests (CEL assertions)
task validate   # Render output and verify generated Go code compiles
task ci         # Full pipeline: lint + test + validate
task publish VERSION=1.0.0   # Push to OCI registry
```

## Conventions

- **Commits**: Conventional commits, GPG/SSH signed, DCO sign-off
- **Versioning**: Semver tags (v1.0.0). Breaking template changes = major bump.
- **No backward compatibility**: Templates may change between versions

## Solution Structure

- `scafctl/solution.yaml` -- Resolvers, workflow actions, and inline test cases
- `scafctl/templates/**/*.tpl` -- Go templates rendered with user inputs
- `scripts/validate-output.sh` -- Renders and compiles generated output
- `scripts/configure-repo.sh` -- Configures GitHub repo settings via gh CLI
