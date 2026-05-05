---
description: "scafctl: Verify MCP tool exposure, auth, and platform/catalog readiness at session start"
tools:
  - terminal
  - scafctl/*
argument-hint: "Optionally specify which tool categories you want ready (for example: platform, ServiceNow, catalog)"
---

Run a scafctl MCP startup readiness check for the current session.

## Goals

- Verify the scafctl MCP server is running and advertising tools
- Verify auth readiness for tools that require authentication
- Check that the requested tool categories are exposed
- Report scafctl version and suggest upgrade if not on latest
- Complete the check quickly with minimal network and payload overhead

## Performance Profile (Do This First)

- Target completion time: 30-60 seconds on a healthy environment.
- Prefer MCP tools over shell commands whenever an equivalent exists.
- Run read-only checks in parallel where possible.
- Avoid large payload endpoints unless strictly required.
- If a tool returns a large payload, extract only needed fields with CEL.

Fast path order:
1. MCP `get_version` + MCP `auth_status` (parallel)
2. MCP `list_auth_handlers` (optional but useful for missing-handler diagnosis)
3. `scafctl mcp list -o json` once, then validate required tool names with set-membership
4. One lightweight MCP call per requested category only
5. Stop when all required checks are satisfied

## Checklist

### Step 1: Check scafctl version

Run:

~~~text
scafctl version
~~~

Compare the installed version against the latest 1.x release. If not on the
latest, suggest upgrading before proceeding. Only 1.x versions matter
(latest alpha/beta/GA).

Speed guidance:
- Prefer MCP `get_version` for installed version.
- For latest version, query a minimal endpoint first (`/releases/latest`) and only
  fetch full release lists if needed to resolve latest 1.x.
- Do not call broad release/history endpoints unless minimal checks are inconclusive.

### Step 2: Verify server-side tool registration

Run:

~~~text
scafctl mcp list -o json
~~~

Confirm the expected tool categories appear. The server exposes tools in
these categories:

Speed guidance:
- Run this command exactly once.
- Parse once and validate required tool names by membership checks.
- Do not make one tool call per tool name.
- Catalog registration source of truth is `get_config(section: catalogs)`.
- Treat `catalog_list_registered` as secondary verification, not primary truth.

**Core solution tools**:
`scaffold_solution`, `lint_solution`, `inspect_solution`, `dry_run_solution`,
`run_solution`, `run_provider`, `preview_resolvers`, `preview_action`,
`validate_expression`, `validate_expressions`, `evaluate_cel`,
`evaluate_go_template`

**Discovery and reference**:
`list_providers`, `get_provider_schema`, `get_provider_output_shape`,
`list_cel_functions`, `list_go_template_functions`, `list_lint_rules`,
`list_examples`, `get_example`, `explain_concepts`, `explain_kind`,
`explain_error`, `explain_lint_rule`, `get_solution_schema`

**Testing**:
`generate_test_scaffold`, `run_solution_tests`, `list_tests`

**Catalog**:
`catalog_search`, `catalog_list_solutions`, `catalog_list_platforms`,
`catalog_list_registered`, `catalog_inspect`

**Platform** (requires Entra auth):
`platform_assets_query`, `platform_services_query`,
`platform_docs_search`, `platform_docs_list_sites`

**ServiceNow** (requires Entra auth):
`platform_servicenow_create_incident`, `platform_servicenow_get_incident`,
`platform_servicenow_search_incidents`, `platform_servicenow_search_kb`,
`platform_servicenow_update_incident`

**Migration**:
`migrate_discover_solutions`, `migrate_solution`,
`migrate_validate_converted`, and other `migrate_*` tools

**Configuration and auth**:
`auth_status`, `get_version`, `get_config`

### Step 3: Verify authentication

Run:

~~~text
scafctl auth status
~~~

Check for:
- **GitHub** auth: needed for github provider, catalog operations
- **Entra** auth: needed for platform, ServiceNow, and Ford API tools
- **ford-quay** auth: needed for catalog push/pull from Ford registry

If auth handlers are missing or expired, tell the user which tool
categories will not work and how to authenticate:

~~~text
scafctl auth login github
scafctl auth login entra
scafctl auth login ford-quay
~~~

Speed guidance:
- Use MCP `auth_status` as primary source.
- Use CLI output only as a cross-check, not as the primary path.

### Step 4: Verify tool availability in chat

Call `auth_status` or `get_version` via MCP to confirm the scafctl MCP
server is reachable from the chat runtime (not just from the terminal).

If the MCP call fails, the server may not be configured. Check
`.vscode/mcp.json` for the scafctl server entry.

If the user requested specific tool categories (platform, ServiceNow,
catalog), attempt to call a lightweight tool from that category to
confirm it works end-to-end.

Category probes (prefer these low-cost calls):
- Core reachability: `get_version` or `auth_status`
- Catalog: `get_config(section: catalogs)` (source of truth) + `catalog_list_registered` (consistency check)
- Platform docs: `platform_docs_list_sites`
- Platform assets: `platform_assets_query` with minimal fields
- ServiceNow: `platform_servicenow_search_kb` with `limit: 1`

Do not use expensive or write-capable operations for readiness probes.

### Step 5: Report final readiness

Give a short summary:

- **Version**: installed version and whether it is current
- **MCP server**: running / not running, total tool count
- **Auth**: which handlers are active, which are missing
- **Requested categories**: available / unavailable with reasons
- **Action items**: any auth logins or upgrades needed

## Rules

- Always distinguish between "tool registered server-side" and "tool
  callable from chat" -- these can differ
- Do not claim a tool is unavailable until both checks are done
- For ServiceNow tools, remind the user that explicit confirmation is
  required before creating or updating incidents
- Keep the summary concise -- use a table for category status
- If a check fails, report exactly which check failed and continue remaining checks when safe
- Prefer "degraded" over "unavailable" when registration exists but runtime/auth probe fails
- If `catalog_list_registered` and `get_config(section: catalogs)` differ, report MCP catalog listing mismatch and use `get_config` (or CLI `scafctl catalog remote list`) as source of truth
- Include elapsed time and slowest step in the final summary
