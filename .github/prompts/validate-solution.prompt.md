---
description: "scafctl: Validate a solution -- lint, check expressions, dry-run, and report issues"
agent: "solution-author"
tools:
  - scafctl/*
argument-hint: "Optionally specify the solution file path (defaults to ./scafctl/solution.yaml)"
---

Validate the scafctl solution at `./scafctl/solution.yaml` (or the path the user specifies).

Run these checks in order and report results for each:

1. **Lint** -- Call `lint_solution` to check YAML structure. If there are findings, call `explain_lint_rule` for each and suggest fixes. Use `lint_rules` to see all available rules. The user can also run `scafctl lint explain <rule>` or `scafctl lint rules` from the CLI.

2. **Expressions** -- Call `validate_expressions` to syntax-check all CEL and Go template expressions in the solution.

3. **Dry run** -- Call `dry_run_solution` to execute resolvers in mock mode and build the action graph without side effects. Use `--validate-all` to show all errors at once. Report any resolver failures or action graph errors.

4. **Summary** — Present a clear pass/fail summary:
   - ✅ Lint: X findings (or clean)
   - ✅ Expressions: all valid (or list failures)
   - ✅ Dry run: resolvers OK, action graph OK (or list issues)

If all checks pass, show the correct run command:
- Has `spec.workflow.actions`: `scafctl run solution -f ./scafctl/solution.yaml -r key=value`
- Resolver-only: `scafctl run resolver -f ./scafctl/solution.yaml key=value`
