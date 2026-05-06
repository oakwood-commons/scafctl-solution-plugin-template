---
description: "scafctl: Debug a failing solution -- inspect, preview resolvers, explain errors, and compare snapshots"
agent: "solution-author"
tools:
  - scafctl/*
  - terminal
argument-hint: "Describe the error or paste the failure output"
---

Help the user debug a failing scafctl solution at `./scafctl/solution.yaml` (or the path the user specifies).

## Workflow

### Step 1: Understand the Failure

Ask the user to describe or paste the error. Determine which phase failed:
- **Load/parse** -- YAML syntax, schema violations
- **Resolver execution** -- provider errors, dependency failures, expression errors
- **Action execution** -- file write failures, provider errors, conflict issues

### Step 2: Inspect the Solution

Call `inspect_solution` to get the full resolver graph and action plan. Look for:
- Incorrect DAG ordering (the DAG auto-calculates from expression references, but explicit `dependsOn` overrides may be wrong)
- Resolvers with `when` clauses that might be skipping unexpectedly
- Circular dependencies

### Step 3: Diagnose Based on Phase

**For load/parse errors:**
1. Call `lint_solution` to check YAML structure
2. Call `validate_expressions` to syntax-check all CEL and Go template expressions
3. Call `explain_lint_rule` for any findings

**For resolver errors:**
1. Call `preview_resolvers` to test resolver outputs -- use the `resolver` param to focus on the failing one
2. Call `explain_error` with the error message for detailed guidance
3. Call `evaluate_cel` to test CEL expressions in isolation with sample data
4. Use `scafctl eval cel --expression '<expr>'` or `scafctl eval template -t '<tmpl>'` for quick terminal testing
5. Call `evaluate_go_template` to test Go templates with sample data
6. Use `--validate-all` flag to show all validation/resolver errors at once
7. Add a `debug` provider to a resolver to inspect data at specific points in the graph

**For auth errors:**
1. Run `scafctl auth diagnose` to check for auth issues
2. Run `scafctl auth status` to check token status
3. Ensure the user has logged in with the required auth handler

**For action errors:**
1. Call `preview_action` to dry-run the action graph and see materialized inputs
2. Call `dry_run_solution` for a full dry-run (resolvers in mock mode, action graph built but not executed)
3. Check `--on-conflict` strategy if file write errors occur

### Step 4: Compare with Known Good State (if available)

If the user has a previous working snapshot:
1. Call `show_snapshot` to inspect the execution snapshot
2. Call `diff_snapshots` to compare two snapshots and detect regressions

### Step 5: Fix and Verify

1. Suggest specific fixes based on the diagnosis
2. Apply the fix
3. Re-run `lint_solution` and `validate_expressions` to confirm the fix is valid
4. Re-run the solution or use `preview_resolvers` to verify

## Common Issues

| Symptom | Likely Cause | Tool to Use |
|---------|-------------|-------------|
| "resolver not found" | Typo in resolver name or reference the DAG cannot resolve | `inspect_solution` |
| "expression error" | Invalid CEL syntax or wrong variable name | `validate_expressions`, `evaluate_cel` |
| "template error" | Go template syntax error or missing data | `evaluate_go_template` |
| "provider error" | Wrong input fields or types | `get_provider_schema` |
| "conflict" error | File already exists | Re-run with `--on-conflict` flag |
| Resolver returns unexpected value | Wrong provider or transform | `preview_resolvers` |
| Auth errors (401, 403, token expired) | Missing or expired auth token | `scafctl auth diagnose`, `scafctl auth status` |

## Rules

- Always inspect before guessing at fixes
- Use MCP tools to verify -- don't assume based on the error message alone
- Test fixes with `preview_resolvers` before re-running the full solution
- If the error looks like a scafctl bug, flag it to the user immediately
