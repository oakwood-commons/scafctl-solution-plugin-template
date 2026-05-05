---
applyTo: '**'
---
# Solution Repository -- Plugin Template

This is a scafctl solutions repository. It contains a solution that scaffolds
complete provider and auth-handler plugin projects for the scafctl ecosystem.

## Key Facts

- **No Go code**: This repo contains only YAML and Go template files
- **Testing**: Use `scafctl lint` and `scafctl test functional` -- NOT Go test commands
- **Templates**: Use `<%` / `%>` delimiters to avoid conflicts with generated `{{`/`}}` content
- **Placeholders**: `PLUGIN_NAME` and `PKG_NAME` in file paths are replaced at render time

## Execution Model

A solution has two phases: **resolvers** (data) then **actions** (side effects).
Resolvers gather and transform data -- parameters, API calls, file reads,
expressions. Actions consume resolver output and perform side effects -- writing
files, running commands, displaying messages. All resolvers complete before any
action runs. Actions read resolver values via the `_` map (e.g., `_.myResolver`)
but cannot feed data back to resolvers.

Use `scafctl run resolver` to run resolvers without actions (useful for debugging
data). Use `scafctl run solution` to run both phases (requires `spec.workflow`).

## AI Workflow

Follow this workflow when working on solutions:

1. **Create** -- Use `/create-solution` or `scaffold_solution` MCP tool
2. **Validate** -- Use `/validate-solution`, or call `lint_solution`, `validate_expressions`, and `dry_run_solution` MCP tools directly
3. **Test** -- Use `/test-solution`, or call `generate_test_scaffold` then `run_solution_tests`
4. **Run** -- Run `scafctl run solution -r key=value` or call `run_solution` MCP tool

**After every solution YAML change**, verify by running these two commands:

~~~bash
scafctl lint                # must exit 0 with no errors
scafctl run resolver        # must exit 0 -- resolvers must always work
~~~

`scafctl run resolver` is the ground truth for whether a solution's data layer
is correct. If it fails, the solution is broken regardless of what lint or MCP
tools say. Always run it after editing solution YAML, adding/changing resolvers,
or modifying provider inputs. Do not consider a solution change complete until
both commands pass.

## MCP Preference

This workspace has access to scafctl through MCP. Prefer MCP tools over shell
commands whenever an equivalent exists.

- Use MCP for schema and provider discovery: `get_solution_schema`, `list_providers`, `get_provider_schema`, `get_provider_output_shape`
- Use MCP for validation and testing: `lint_solution`, `validate_expressions`, `run_solution_tests`, `dry_run_solution`
- Use MCP for debugging: `inspect_solution`, `preview_resolvers`, `preview_action`, `explain_error`
- Fall back to CLI commands when you need the exact user-facing invocation, terminal output, or behavior that MCP does not expose

## Build & Test Commands

~~~bash
task lint       # Lint solution YAML
task test       # Run functional tests (CEL assertions)
task validate   # Render output and verify generated Go code compiles
task ci         # Full pipeline: lint + test + validate
task publish VERSION=1.0.0   # Push to OCI registry
~~~

## CLI Quick Reference

scafctl auto-discovers `./scafctl/solution.yaml` when run from the repo root. Use `-f` only for non-standard paths.

~~~bash
# Lint
scafctl lint

# Run all actions
scafctl run solution -r key=value

# Run resolvers only
scafctl run resolver

# Test
scafctl test functional

# Evaluate expressions in isolation
scafctl eval cel --expression '1 + 2'
scafctl eval template -t '{{ .name }}' -v name=hello

# Discover CLI commands and flags
scafctl get commands
~~~

## MCP Tools

The scafctl MCP server exposes 70+ tools. **Prefer MCP tools over CLI commands**
when available. Key tools by category:

### Core Solution Development

- `scaffold_solution`, `inspect_solution`, `get_run_command`
- `lint_solution`, `validate_expression`, `validate_expressions`
- `dry_run_solution`, `preview_resolvers`, `preview_action`
- `run_solution`, `run_provider`

### Discovery & Reference

- `list_providers`, `get_provider_schema`, `get_provider_output_shape`
- `list_cel_functions`, `list_go_template_functions`
- `list_lint_rules`, `explain_lint_rule`, `explain_kind`
- `explain_error`, `explain_concepts`

### Testing & Execution

- `generate_test_scaffold`, `run_solution_tests`, `list_tests`
- `diff_solution`, `diff_snapshots`, `show_snapshot`
- `render_solution`

### Catalog

- `catalog_search`, `catalog_list_solutions`, `catalog_list_registered`
- `catalog_inspect`

### Configuration & Auth

- `auth_status` -- Check which auth handlers are active
- `list_auth_handlers` -- See available auth flows
- `get_version` -- scafctl version and build info
- `get_config` -- Current configuration (catalogs, settings)

## Key Conventions

- Solution YAML: `./scafctl/solution.yaml`
- Templates: `./scafctl/templates/` (Go templates with `<%`/`%>` delimiters, `.tpl` files)
- Always validate with MCP tools before considering work complete
- Always prefix relative paths with `./` in responses
- **Upgrade first**: Check `scafctl version` and compare against latest release
- **Authentication**: Use `scafctl auth login <handler>` (never suggest external CLI
  auth like `az login` or `gcloud auth login`)

## Built-in Providers

25+ built-in providers. Always check `list_providers` and `get_provider_schema`
before suggesting external tools.

Key providers:
- **github** -- Full GitHub API (issues, PRs, commits, releases, branches, tags, rulesets, security)
- **http** -- Generic HTTP/HTTPS with auth, pagination, polling
- **git** -- Local git operations
- **exec** -- Shell commands (embedded POSIX shell, works on all platforms). Last resort.
- **file**, **directory** -- Filesystem operations
- **env** -- Environment variables
- **message** -- Terminal output and structured data display
- **cel**, **go-template** -- Data transformation and rendering
- **validation** -- Regex and CEL-based validation

## Solution Structure

- `scafctl/solution.yaml` -- Resolvers, workflow actions, and test cases
- `scafctl/templates/**/*.tpl` -- Go templates rendered with user inputs
- `scafctl/static/.github/**` -- Static AI support files copied into generated repos
- `scripts/validate-output.sh` -- Renders and compiles generated output
- `scripts/configure-repo.sh` -- Configures GitHub repo settings via gh CLI

## Generated Provider Guidance

When editing provider scaffolding, reason about the generated provider contract, not just template syntax.

- Keep `GetProviderDescriptor`, `ExecuteProvider`, and `DescribeWhatIf` behavior aligned.
- Treat schema fields, README examples, generated tests, and AI guidance as one contract surface.
- Use `.github/instructions/scafctl-provider.instructions.md` when editing provider templates.
- Use `.github/prompts/provider-implementation.prompt.md` when implementing provider-facing scaffold changes.
- Use `.github/prompts/provider-review.prompt.md` to review provider-facing scaffold changes.

## Generated Auth-Handler Guidance

When editing auth-handler scaffolding, reason about the generated authentication lifecycle, not just template syntax.

- Keep `GetAuthHandlers`, `Login`, `GetStatus`, and `GetToken` behavior aligned.
- Treat flows, capabilities, claims, token behavior, tests, and README examples as one contract surface.
- Use `.github/instructions/scafctl-auth-handler.instructions.md` when editing auth-handler templates.
- Use `.github/prompts/auth-handler-implementation.prompt.md` when implementing auth-handler scaffold changes.
- Use `.github/prompts/auth-handler-review.prompt.md` to review auth-handler scaffold changes.

## Conventions

- **Commits**: Conventional commits, GPG/SSH signed, DCO sign-off
- **Versioning**: Semver tags (v1.0.0). Breaking template changes = major bump.
- **No backward compatibility**: Templates may change between versions

## Issue Reporting

When you identify a potential scafctl bug or non-idiomatic limitation:

1. Flag it to the user immediately with clear description
2. Try 2-3 different approaches before giving up
3. Ask the user before implementing non-idiomatic workarounds
4. Use the `issue-creator` agent (never create issues directly)
