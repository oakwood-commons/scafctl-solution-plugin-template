---
name: provider-reference
description: "Complete scafctl provider catalog with capabilities, input fields, and usage examples. Use when selecting a provider, writing resolver/action inputs, or debugging provider errors."
---

# scafctl Provider Reference

scafctl uses scafctl's provider system. Always call `get_provider_schema` for exact field details before using a provider -- this reference is a quick lookup guide.

## Provider Capabilities

| Capability | Used In | Purpose |
|-----------|---------|---------|
| `from` | `resolve.with` | Produce a value |
| `transform` | `transform.with` | Reshape a value |
| `validation` | `validate.with` | Check a value |
| `action` | `workflow.actions` | Perform side-effects |
| `authentication` | Auth resolvers | Produce auth tokens |

## Quick Reference

| Provider | Capabilities | Purpose | Details |
|----------|-------------|---------|---------|
| parameter | from | CLI parameters via `-r key=value` | [data-providers.md](./references/data-providers.md) |
| env | from | Read/set/list environment variables | [data-providers.md](./references/data-providers.md) |
| static | from | Literal pass-through values | [data-providers.md](./references/data-providers.md) |
| file | from, action | Read/write files and file trees | [data-providers.md](./references/data-providers.md), [action-providers.md](./references/action-providers.md) |
| exec | from, transform, action | Run shell commands (embedded POSIX) | [data-providers.md](./references/data-providers.md), [action-providers.md](./references/action-providers.md) |
| http | from | HTTP requests with auth, pagination, retry | [data-providers.md](./references/data-providers.md) |
| git | from, action | Local git operations | [data-providers.md](./references/data-providers.md) |
| github | from, transform, action | Full GitHub API (GraphQL + REST) | [github-provider.md](./references/github-provider.md) |
| hcl | from, transform | Parse, format, validate, generate HCL/Terraform | [hcl-provider.md](./references/hcl-provider.md) |
| secret | from | Encrypted secrets store | [data-providers.md](./references/data-providers.md) |
| identity | from | Auth identity info (claims, status) | [data-providers.md](./references/data-providers.md) |
| metadata | from | Runtime metadata (version, solution info) | [data-providers.md](./references/data-providers.md) |
| debug | from, transform, validation, action | Inspect resolver data during execution | [data-providers.md](./references/data-providers.md) |
| sleep | from | Delay execution for rate limiting | [data-providers.md](./references/data-providers.md) |
| solution | from | Cross-solution references | [data-providers.md](./references/data-providers.md) |
| cel | transform | CEL expression evaluation | [transform-providers.md](./references/transform-providers.md) |
| go-template | transform, action | Go template rendering | [transform-providers.md](./references/transform-providers.md), [action-providers.md](./references/action-providers.md) |
| validation | validation | CEL-based rule validation | [transform-providers.md](./references/transform-providers.md) |
| directory | action | Create, remove, copy, list directories | [action-providers.md](./references/action-providers.md) |
| message | action | Terminal output and structured data display | [action-providers.md](./references/action-providers.md) |

## Key Rules

- **Never set `type: string`** on resolvers using http, github, hcl, or file (parse mode) -- they return objects
- **Prefer `raw: true`** on exec and env when you just need the value string
- **Always use `get_provider_schema`** MCP tool for exact field names before writing YAML
- **Use `authProvider: entra`** on http requests to Ford APIs -- never hardcode tokens
- **Mark `sensitive: true`** on resolvers using the secret provider