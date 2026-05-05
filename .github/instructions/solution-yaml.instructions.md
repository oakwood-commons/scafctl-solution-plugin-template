---
applyTo: "scafctl/**/*.yaml"
---

# Solution YAML Conventions

Solution YAML follows the scafctl schema (`apiVersion: scafctl.io/v1`).

## Execution Model

Resolvers gather and transform data. Actions perform side effects. scafctl
executes them in two phases:

1. **Resolvers** run first, in dependency order (parallelized where possible).
   Each resolver produces a value accessible via the `_` map (e.g., `_.myResolver`).
2. **Actions** run after all resolvers complete, also in dependency order.
   Actions consume resolver output through `_` but cannot produce values
   that other resolvers or actions reference via `_`.

Resolvers never see action output. Actions can see other action results
via `__actions` for sequencing, but the primary data flow is
resolvers --> actions.

## Required Fields

- `apiVersion: scafctl.io/v1`
- `kind: Solution`
- `metadata.name`: lowercase with hyphens, 3-60 chars
- `metadata.version`: valid semver (e.g., `1.0.0`) -- optional for local dev, required for `build`/`publish`

## Recommended Metadata

Always include these fields for catalog discovery and MCP tool integration:

- `metadata.displayName`: human-readable name shown in catalog listings and UI
- `metadata.description`: what the solution does (used by `catalog_search`)
- `metadata.category`: grouping label (e.g., `developer-tools`, `infrastructure`, `security`, `observability`). Must be at least 3 characters.
- `metadata.tags`: list of keywords for search and filtering

## Top-Level Structure

~~~yaml
apiVersion: scafctl.io/v1
kind: Solution
metadata:
  name: my-solution
  displayName: My Solution
  version: 1.0.0
  description: What this solution does
  category: developer-tools
  tags:
    - example
    - starter

bundle:            # Files to include when building/publishing
  include:
    - "templates/**"
    - "static/**"

compose:           # Merge other YAML files into this solution
  - tests.yaml

spec:
  resolvers:       # Data gathering and transformation
    # ...
  workflow:        # Side-effects (file writes, commands, messages)
    actions:
      # ...
  testing:         # Functional tests (usually in tests.yaml via compose)
    cases:
      # ...
~~~

### `bundle.include`

When building a solution for publishing (`scafctl build solution`), only files matching `bundle.include` globs are packaged. Without `bundle`, only the solution YAML itself is included.

~~~yaml
bundle:
  include:
    - "templates/**"   # Go template files
    - "static/**"      # Static files to copy as-is
~~~

### `compose`

Merges other YAML files into the solution at load time. Use this to keep tests, large resolver groups, or action groups in separate files.

~~~yaml
compose:
  - tests.yaml       # Merged into spec.testing
~~~

## Resolver Rules

- Resolver names: use **camelCase** (e.g., `repoInfo`, `defaultBranch`). Avoid kebab-case -- dashes break dot notation in CEL (`_.my-resolver` parses as subtraction) and Go templates, forcing awkward `_["my-resolver"]` or `index . "my-resolver"` syntax. The `__` prefix is reserved for built-in context variables.
- Never set `type: string` on resolvers returning objects (e.g., `http`, `directory`, `go-template`)
- When in doubt, omit the `type` field entirely
- Do NOT add explicit `dependsOn` when the DAG can infer order from `rslvr:`, `expr:`, or `tmpl:` references. Only use `dependsOn` when there is no expression reference to follow -- e.g., a resolver consumed only inside an external `.tpl` file, or side-effect ordering between actions
- Use `when` with CEL for conditional execution
- Keep each resolver focused on one task

## ValueRef Format

Inputs use four value formats:

| Format | Syntax | When to use |
|--------|--------|-------------|
| Literal | `literal: "value"` | Static values |
| Resolver ref | `rslvr: resolverName` | Whole resolver output |
| CEL expression | `expr: "_.name + '-svc'"` | Typed values: objects, arrays, numbers, booleans, filtered data |
| Go template | `tmpl: "{{ ._.name }}"` | String rendering only |

## Expression Rules

- `when:` clauses require CEL (`expr:`)
- Prefer `when` clauses over ternary operators
- Prefer `transform` phase over complex inline CEL
- If a CEL expression needs multiple lines or nested ternaries, split into separate resolvers
- Never use CEL for multi-line string building -- use Go templates

## Action Rules

- Action names: `^[a-zA-Z_][a-zA-Z0-9_-]*$`
- Actions go under `spec.workflow.actions.<name>`
- Use `dependsOn` to order actions only when there is no implicit dependency through resolver references
- Do NOT add `dependsOn` between actions that have no data dependency. Actions execute concurrently by default, which is usually desirable for performance
- Use `when` for conditional actions
- **Use `__actions` for action-to-action data flow**: When a message or downstream action needs results from an upstream action (e.g., files written by write-tree), use `__actions["action-name"].results` instead of re-deriving from resolver data. This shows actual results (files created, skipped, unchanged) rather than intended inputs.

### Action vs Resolver Structure

Actions and resolvers have **different schemas**. Do NOT mix them:

~~~yaml
# WRONG -- resolver-style with: array inside an action
actions:
  display:
    with:
      - provider: message
        inputs:
          message: "hello"

# CORRECT -- actions use flat provider/inputs directly
actions:
  display:
    provider: message
    inputs:
      message: "hello"
~~~

Resolvers use `resolve.with: [{provider, inputs}]` (array of steps).
Actions use `provider` + `inputs` directly (flat, single provider per action).

## Resolver Validate Phase

The `validate` block on a resolver checks the resolved value before it is
used downstream. **Only `provider: validation` is valid** in the validate
phase -- other providers (`cel`, `exec`, etc.) will silently do nothing.

~~~yaml
resolvers:
  appName:
    resolve:
      with:
        - provider: parameter
          inputs:
            key: appName
    validate:
      with:
        - provider: validation    # <-- MUST be "validation", not "cel"
          inputs:
            failWhen: 'size(__self) < 3'
            message: "App name must be at least 3 characters"
~~~

### Validate message context

The `message` field in validation supports `expr:` and `tmpl:`. In the
validate context, resolver values are accessed by name directly (NOT via
`_`):

~~~yaml
# Correct -- resolver names are top-level keys in validate message
message:
  tmpl: "{{ .appName }} is invalid"
message:
  expr: '"Invalid: " + _.appName'
~~~

### Common mistake

~~~yaml
# WRONG -- silently does nothing, lint won't catch it
validate:
  with:
    - provider: cel
      inputs:
        expression: 'size(__self) > 0'

# CORRECT -- validation actually fires
validate:
  with:
    - provider: validation
      inputs:
        failWhen: 'size(__self) == 0'
        message: "Must not be empty"
~~~

Note that `failWhen` uses **inverted** logic compared to a `cel` assertion:
`failWhen` triggers failure when the expression is **true**.

## Action Guarding Patterns

Use `when` on actions to create opt-in actions that only run when explicitly
selected via `--action`. This is common for solutions with multiple modes
(e.g., lint, test, deploy, help).

~~~yaml
resolvers:
  action:
    resolve:
      with:
        - provider: parameter
          inputs:
            key: action
        - provider: static
          inputs:
            value: ""

actions:
  deploy:
    when:
      expr: '_.action == "deploy"'
    provider: exec
    inputs:
      command: kubectl apply -f .

  help:
    when:
      expr: '_.action == "" || _.action == "help"'
    provider: message
    inputs:
      type: info
      message: |
        Available actions: deploy, help
        Usage: scafctl run solution -r action=deploy
~~~

For `run action` task runners, use `--action` flag instead:

~~~bash
# Run specific action by name (no parameter needed)
scafctl run action deploy
~~~


## Exec Provider Guidelines

The `exec` provider runs commands via a shell. By default it uses an embedded
cross-platform POSIX shell, but you can select a different shell with the
`shell` input. It is powerful but has significant trade-offs. Treat it as the
**last resort**, not the first choice.

### Shell selection

The `shell` input controls which shell executes the command:

| Value | Shell | Notes |
|-------|-------|-------|
| `auto` | Auto-detect (default) | Uses the embedded POSIX shell |
| `sh` | POSIX sh | Portable across Linux/Mac |
| `bash` | Bash | Must be installed |
| `pwsh` | PowerShell Core | Cross-platform (Windows, Linux, Mac) -- must be installed |
| `cmd` | Windows cmd.exe | Legacy Windows only |

When writing platform-conditional resolvers, use `shell: pwsh` for
PowerShell-native commands. Do NOT shell out to
`powershell -NoProfile -c "..."` from the POSIX shell -- use `shell: pwsh`
directly instead.

### When NOT to use exec

- **A built-in provider already does it** -- Always check `list_providers`
  first. Use `message` not `exec`+`echo`, `file` not `exec`+redirects,
  `http` not `exec`+`curl`, `github` not `exec`+`gh`, `git` not `exec`+`git`,
  `env` not `exec`+`printenv`, `directory` not `exec`+`mkdir`/`ls`.
- **The solution may run as an API** -- Solutions published to a catalog can
  be executed via the scafctl API service, where `exec` is disabled for
  security. If your solution needs to work in both CLI and API contexts,
  avoid `exec` entirely.
- **Portability matters** -- `exec` commands may not work across operating
  systems. Built-in providers are cross-platform by design.
- **The binary may not exist** -- There is no guarantee that the program you
  call is installed on the user's machine. Built-in providers ship with
  scafctl and are always available. If you must use `exec`, document the
  dependency and consider adding a validation resolver that checks for the
  binary (e.g., `which docker` / `command -v docker`).

### When exec IS appropriate

- **Running external programs** that have no built-in provider equivalent:
  `docker`, `make`, `terraform`, `helm`, `kubectl`, `npm`, etc.
- **Replacing a task runner** (e.g., Taskfile, Makefile) where the solution
  IS the task runner and shell commands are the whole point.
- **One-off system commands** that are inherently local-only and will never
  run via API (e.g., opening a browser, clipboard operations).

### Decision checklist

1. Can a built-in provider do this? --> Use the built-in provider
2. Will this solution ever run via API? --> Do not use exec
3. Is this an external CLI tool? --> exec is the right choice
4. Is this a shell built-in (echo, cat, grep)? --> Use a built-in provider instead

### Anti-pattern: bash logic inside exec

Never embed if/elif/fi, OS detection, or branching logic inside an exec
command. Detect the platform with a resolver, then use separate resolvers
with `when` clauses. Each resolver should do one thing.

Bad -- bash conditionals inside exec:

~~~yaml
localIp:
  resolve:
    with:
      - provider: exec
        inputs:
          command: |
            if command -v powershell >/dev/null 2>&1; then
              powershell -NoProfile -c "(Get-NetIPAddress ...)"
            elif command -v ip >/dev/null 2>&1; then
              ip -4 addr show | grep ...
            fi
~~~

Good -- metadata provider + conditional resolvers:

~~~yaml
runtimeInfo:
  resolve:
    with:
      - provider: metadata

localIpWindows:
  when:
    expr: '_.runtimeInfo.os == "windows"'
  resolve:
    with:
      - provider: exec
        inputs:
          shell: pwsh
          command: >-
            (Get-NetIPAddress -AddressFamily IPv4
            | Where-Object {$_.IPAddress -like '19.*'}
            | Select-Object -First 1).IPAddress
          raw: true

localIpLinux:
  when:
    expr: '_.runtimeInfo.os == "linux"'
  resolve:
    with:
      - provider: exec
        inputs:
          command: ip -4 addr show | grep -oE '19\.[0-9]+\.[0-9]+\.[0-9]+' | head -1
          raw: true

localIp:
  resolve:
    with:
      - provider: cel
        inputs:
          expression: >-
            _.runtimeInfo.os == "windows"
              ? _.localIpWindows
              : _.localIpLinux
~~~

This pattern is clearer, testable per-platform, and each resolver has a
single responsibility.

### Exec runs in workspace CWD

The exec provider runs commands in the user's workspace directory -- not in
a sandbox or the solution bundle directory. This is by design: exec commands
need access to the user's project files (e.g., `git`, `docker`,
`terraform`).

This means exec commands see whatever state the user's workspace is in. Do
not assume:

- A `.git` directory exists or has a configured remote
- Specific files or directories are present
- The CWD is the repo root (it could be a subdirectory)

These are solution authoring problems, not provider bugs. Always guard exec
resolvers with fallbacks or conditions.

### Always handle exec failures

Exec commands can fail for many reasons: missing binaries, wrong CWD, no
network, no git remote. Never assume success. Either provide a fallback
value or check `exitCode`.

Bad -- assumes git remote always exists:

~~~yaml
gitRemote:
  resolve:
    with:
      - provider: exec
        inputs:
          command: git remote get-url origin
          raw: true
~~~

Good -- fallback chain with parameter override:

~~~yaml
gitRemote:
  description: Git remote URL (auto-detected, or ask the user)
  resolve:
    with:
      - provider: exec
        inputs:
          command: git remote get-url origin
          raw: true
      - provider: parameter
        inputs:
          key: gitRemote
          prompt: "Could not detect git remote. Enter the repo URL"
      - provider: static
        inputs:
          value: ""
~~~

The chain tries exec first, falls back to prompting the user, and defaults
to empty if neither works. This way the solution never blows up -- the user
always gets a chance to supply the value.

Good -- check exitCode in transform:

~~~yaml
gitTag:
  resolve:
    with:
      - provider: exec
        inputs:
          command: git describe --abbrev=0 --tags
  transform:
    with:
      - provider: cel
        inputs:
          expression: >-
            __self.exitCode == 0 ? __self.stdout.trim() : "0.0.1-dev"
~~~

Good -- skip entirely when not in a git repo:

~~~yaml
isGitRepo:
  resolve:
    with:
      - provider: exec
        inputs:
          command: git rev-parse --is-inside-work-tree
  transform:
    with:
      - provider: cel
        inputs:
          expression: '__self.exitCode == 0'

gitRemote:
  when:
    expr: '_.isGitRepo == true'
  resolve:
    with:
      - provider: exec
        inputs:
          command: git remote get-url origin
          raw: true
~~~

## Testing

- Tests go in a separate `tests.yaml` file, composed via `compose: [tests.yaml]`
- Do not put tests inline in the solution YAML
- Use `config.files` for files shared by all tests (avoids repeating `files` on every case)
- Files in `bundle.include` are auto-copied to test sandboxes -- no explicit `files` entries needed
- Directory paths (e.g., `files: [templates/]`) work with dot-prefixed subdirs like `.github/`
- Use template cases (`_` prefix) with `extends` to share common config across tests
- Debug test failures with `-o json` first -- it includes `stdout` and `stderr` on failures
- Use `generate_test_scaffold` or `scafctl test init` for a clean starting point
- Reference `explain_concepts functional-testing` for full template/inheritance docs

## Path Resolution and --base-dir

By default, relative paths in resolvers (e.g., `directory`, `file` providers)
resolve from the solution file's directory. When the CWD differs from the
solution directory, use `--base-dir` to override:

~~~bash
# Auto-discovered ./scafctl/solution.yaml, but paths are relative to repo root
scafctl run resolver --base-dir .
scafctl run solution --base-dir . -r key=value
~~~

This is the recommended fix for the "CWD != solution-dir" problem. Prefer
`--base-dir` over building dual-path fallback chains in resolver expressions.

## run action vs run solution --action

- `scafctl run action <name>` targets a task runner file. It auto-discovers
  `actions.yaml`, NOT `./scafctl/solution.yaml`.
- `scafctl run solution --action <name>` runs specific actions from the
  solution file.
- Do NOT use `run action` when you mean to target the solution file.

## HTTP Provider Auth

The http provider uses **flat** auth fields, not a nested `auth:` object:

~~~yaml
# WRONG -- nested auth object
inputs:
  url: https://api.example.com/data
  auth:
    provider: entra
    scope: "api://app-id/.default"

# CORRECT -- flat authProvider + scope fields
inputs:
  url: https://api.example.com/data
  authProvider: entra
  scope: "api://app-id/.default"
~~~

Available `authProvider` values: `entra`, `github`, `gcp`. The `scope`
field is provider-specific (Entra uses `api://.../.default`, GCP uses
OAuth scopes).

## Validation

Always call `get_provider_schema` before using any provider. Never guess field names.

**After every change to solution YAML**, run both of these and fix any failures
before considering the change complete:

~~~bash
scafctl lint                # schema and structural validation
scafctl run resolver        # runtime validation -- proves resolvers actually work
~~~

Lint catches schema errors. `run resolver` catches runtime errors that lint
cannot detect: missing provider inputs, bad expressions, directory paths that
don't exist, provider configuration errors. Both must exit 0.
