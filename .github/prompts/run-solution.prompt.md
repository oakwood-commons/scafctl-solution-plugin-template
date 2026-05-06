---
description: "scafctl: Run a solution -- choose the right command, flags, and conflict strategy"
agent: "solution-author"
tools:
  - scafctl/*
  - terminal
argument-hint: "Optionally specify the solution file path or describe what you want to run"
---

Help the user run a scafctl solution at `./scafctl/solution.yaml` (or the path the user specifies).

## Workflow

### Step 1: Inspect the Solution

Call `inspect_solution` to understand the solution structure:
- Does it have `spec.workflow.actions`? -> Use `scafctl run solution` (all actions) or `scafctl run solution --action <name>` (specific actions)
- Resolver-only (no workflow)? -> Use `scafctl run resolver`
- Is this an `actions.yaml` task runner? -> Use `scafctl run action <name>`

### Step 2: Identify Required Parameters

Check which resolvers use the `parameter` provider -- these are the inputs the user needs to provide with `-r key=value`. List them with defaults and any validation constraints.

### Step 3: Choose Conflict Strategy

If the solution writes files, explain the `--on-conflict` options:

| Flag | Behavior |
|------|----------|
| `--on-conflict error` | Fail if target file exists (default) |
| `--on-conflict skip-unchanged` | SHA256 compare; skip if identical |
| `--on-conflict skip` | Never write if file exists |
| `--on-conflict overwrite` | Always replace existing files |
| `--on-conflict append` | Append content to existing file |

The default is `--on-conflict error`, which is safest for first runs. For solutions that are meant to be re-run, suggest `--on-conflict skip-unchanged` or use `--force` (shorthand for `--on-conflict skip-unchanged`). Add `--backup` if the user wants `.bak` files before any mutations.

### Step 4: Build and Present the Command

Construct the full command with all flags and present it to the user:

~~~
# Solution with all actions
scafctl run solution -f ./scafctl/solution.yaml -r key=value --on-conflict error

# Specific actions (with transitive dependencies)
scafctl run solution --action lint --action test -f ./scafctl/solution.yaml -r key=value

# Resolver-only
scafctl run resolver -f ./scafctl/solution.yaml -r key=value

# Task runner action
scafctl run action <name>
~~~

### Step 5: Run and Diagnose

If the user wants to run it now, execute in the terminal. If it fails:
1. Check the error message -- use `explain_error` if unclear
2. Use `preview_resolvers` to test resolver outputs in isolation
3. Suggest fixes and re-run

## Rules

- Always inspect before running -- never guess the command
- Always show the full command before executing
- The `-f` flag is optional if `solution.yaml` exists in the current directory (auto-discovery)
- Use `-r key=value` for `run solution`; use positional `key=value` for `run resolver`
- Use `scafctl run solution --action <name>` to run specific actions from a solution file
- Use `scafctl run action <name>` to run tasks from `actions.yaml` (task runner). `run action` auto-discovers `actions.yaml`, NOT the solution file
- Use `--base-dir <path>` when the CWD differs from the solution directory to fix path resolution
- Prefer `--on-conflict error` for safety unless the user specifies otherwise
