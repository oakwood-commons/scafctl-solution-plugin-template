---
description: "scafctl: Write and run functional tests for a solution -- TDD or retrofit tests onto existing solutions"
agent: "solution-author"
tools:
  - scafctl/*
argument-hint: "Optionally specify what to test (e.g., 'add tests for the file-writer action' or 'TDD a new resolver')"
---

Help the user write and run functional tests for the scafctl solution at `./scafctl/solution.yaml` (or the path the user specifies).

## Workflow

Determine whether the user wants to:

- **Retrofit tests** onto an existing solution → Start at Step 1
- **TDD a new feature** → Start at Step 3

### Step 1: Understand the Solution

Call `inspect_solution` to understand the current resolver graph and action plan.

### Step 2: Generate a Test Scaffold

Call `generate_test_scaffold` to create starter test cases covering:
- Resolver smoke tests (do resolvers execute with defaults?)
- Validation failure tests (do invalid inputs get rejected?)
- Action execution tests (do actions receive correct inputs?)

The scaffold output is directly usable -- it generates a `_files-base` template case with `extends: [_files-base]` on all test cases, and uses correct positional action args.

Alternatively, use `scafctl test init -f ./scafctl/solution.yaml` from the CLI to generate a starter test suite.

Present the generated tests and ask the user which to keep, modify, or add to.

### Step 3: Write Test Cases (TDD or Custom)

For TDD, help the user write test cases **before** the implementation:

1. Define the expected behavior as test assertions
2. Write the test case YAML with `command`, `args`, `assertions`, and `files`
3. Run the tests — they should **fail** (red)
4. Implement the resolver/action to make them pass (green)
5. Refactor if needed

Test cases go in `./scafctl/tests.yaml`, a separate file composed into the solution via the `compose` field. This keeps the solution YAML focused on resolvers and actions.

```yaml
# tests.yaml
spec:
  testing:
    config:
      files: [templates/, static/]  # shared by all tests -- no per-test files needed
    cases:
      _base:
        command: [run, resolver]
        args: [-o, json]
      my-test:
        extends: [_base]
        description: What this test validates
        args: [-r, inputName=test-value, -o, json]
        exitCode: 0
        assertions:
          - expression: "__output.resolverName == 'expected'"
            message: "Resolver should return expected value"
```

Make sure `solution.yaml` includes `compose: [tests.yaml]` to merge tests at load time.

### Step 4: Run Tests

Run the tests and report results:

```
scafctl test functional -f ./scafctl/solution.yaml -v
```

Call `run_solution_tests` with `verbose: true` for full assertion details.

Use `scafctl test list -f ./scafctl/solution.yaml` to list available tests without executing them.

### Step 5: Iterate

For each failing test:
1. Run with `-o json` to get `stdout` and `stderr` on failed tests
2. Show the assertion that failed and the actual value
3. Suggest a fix to either the test or the solution
4. Re-run after fixes

## Test Writing Rules

- Use `__output` to access parsed command output in assertions
- Use `config.files` for files shared by all tests -- avoids repeating `files` on every case
- Files in `bundle.include` are auto-copied to test sandboxes -- no explicit `files` entries needed
- Directory paths (e.g., `files: [templates/]`) work with dot-prefixed subdirs like `.github/`
- Use `exitCode` to test both success (0) and expected failures (non-zero)
- Use `extends` and template cases (names starting with `_`) to share common config
- Keep assertions focused — one behavior per assertion, clear failure messages
- For TDD: write the **smallest** failing test first, then implement just enough to pass
- Reference `explain_concepts functional-testing` for full template/inheritance docs
