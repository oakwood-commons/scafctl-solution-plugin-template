---
description: "scafctl: Publish a solution -- build, test, and push to a catalog registry"
agent: "solution-author"
tools:
  - scafctl/*
  - terminal
argument-hint: "Optionally specify the version or target catalog (e.g., '1.0.0 to scafctl-oci')"
---

Help the user build and publish a scafctl solution to a catalog registry.

## Workflow

### Step 1: Validate Before Publishing

Run the full validation suite before building:

1. Call `lint_solution` -- must pass with 0 errors
2. Call `validate_expressions` -- all CEL and Go template expressions must be valid
3. Call `run_solution_tests` with `verbose: true` -- all tests must pass

If any check fails, stop and fix before proceeding.

### Step 2: Determine Version

Check `metadata.version` in the solution YAML. Ask the user:
- Is this the correct version to publish?
- Should it be bumped? (patch/minor/major)

The version can be overridden at build time with `--version`.

### Step 3: Build the Solution

~~~
scafctl build solution -f ./scafctl/solution.yaml
~~~

Or with an explicit version:

~~~
scafctl build solution -f ./scafctl/solution.yaml --version 1.0.0
~~~

Use `--dry-run` first to preview what will be bundled:

~~~
scafctl build solution -f ./scafctl/solution.yaml --dry-run
~~~

### Step 4: Choose the Target Catalog

List available remotes:

~~~
scafctl catalog remote list
~~~

Confirm which catalog to push to. If the user doesn't specify, use the default remote.

### Step 5: Push to Registry

~~~
# Push to default remote
scafctl catalog push <name>@<version>

# Push to a specific catalog
scafctl catalog push <name>@<version> --catalog <catalog-name>
~~~

### Step 6: Verify

Confirm the artifact is in the catalog:

~~~
scafctl catalog list --name <name>
~~~

### Step 7: Update Catalog Index (Optional)

If the target catalog is used by teams without registry enumeration access,
update the discovery index so the new artifact is discoverable:

~~~
# Preview what the index will contain
scafctl catalog index push --dry-run

# Push the updated index
scafctl catalog index push

# Push to a specific catalog
scafctl catalog index push --catalog <catalog-name>
~~~

Ask the user if they want to update the index. Skip for local-only catalogs.

## Rules

- Always validate and test before publishing -- never skip
- Always show the `--dry-run` output before building for the first time
- Never push without user confirmation of the version and target
- If auth fails during push, guide the user through `scafctl catalog login`
