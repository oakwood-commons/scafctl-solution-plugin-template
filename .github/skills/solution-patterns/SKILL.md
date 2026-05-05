---
name: solution-patterns
description: "Common scafctl solution composition patterns with YAML examples. Use when designing solution architecture, wiring resolvers together, building workflows, or debugging resolver/action interactions."
---

# Solution Patterns

Reusable patterns for composing scafctl solutions. Each pattern shows the resolver and action YAML with notes on when and why to use it.

## Pattern: Parameter with Optional Default

Accept user input, fall back to a default when omitted. The parameter provider prompts the user; if they skip it, the static provider supplies the fallback.

~~~yaml
resolvers:
  environment:
    description: Target environment
    resolve:
      with:
        - provider: parameter
          inputs:
            key: environment
        - provider: static
          inputs:
            value: dev
    validate:
      with:
        - provider: validation
          inputs:
            failWhen: '__self not in ["dev", "stage", "prod"]'
          message: "Must be dev, stage, or prod"
~~~

## Pattern: Multi-Provider Fallback Chain

Try multiple providers in order; first non-null result wins. Useful when a value can come from different sources (parameter, env var, file, computed).

~~~yaml
resolvers:
  projectName:
    description: Resolve project name from parameter, env, or git remote
    resolve:
      with:
        - provider: parameter
          inputs:
            key: projectName
        - provider: env
          inputs:
            name: PROJECT_NAME
        - provider: exec
          inputs:
            command: git
            args: [remote, get-url, origin]
      transform:
        with:
          - provider: cel
            inputs:
              expression: >-
                __self.contains("/")
                  ? __self.split("/").slice(-1)[0].replace(".git", "")
                  : __self
~~~

## Pattern: Conditional Resolver with `when`

Only resolve when a condition is met. Useful for mode-dependent logic.

~~~yaml
resolvers:
  mode:
    resolve:
      with:
        - provider: parameter
          inputs:
            key: mode

  prodConfig:
    when:
      expr: '_.mode == "prod"'
    resolve:
      with:
        - provider: http
          inputs:
            url: https://config.internal/prod
            autoParseJson: true

  devConfig:
    when:
      expr: '_.mode == "dev"'
    resolve:
      with:
        - provider: static
          inputs:
            value:
              replicas: 1
              debug: true
~~~

## Pattern: Transform Pipeline

Chain multiple transforms to reshape data step by step. Each transform receives the output of the previous one as `__self`.

~~~yaml
resolvers:
  version:
    resolve:
      with:
        - provider: parameter
          inputs:
            key: version
    transform:
      with:
        - provider: cel
          inputs:
            expression: '__self.trim()'
        - provider: cel
          inputs:
            expression: >-
              __self.startsWith("v") ? __self.substring(1) : __self
    validate:
      with:
        - provider: validation
          inputs:
            failWhen: >-
              !__self.matches("^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)$")
          message: "Must be valid semver (e.g., 1.0.0)"
~~~

## Pattern: Exec with Output Parsing

Run a command and extract structured data from stdout. Always trim exec output.

~~~yaml
resolvers:
  gitBranch:
    type: string
    resolve:
      with:
        - provider: exec
          inputs:
            command: git
            args: [branch, --show-current]
    transform:
      with:
        - provider: cel
          inputs:
            expression: "__self.stdout.trim()"

  gitTagOrFallback:
    type: string
    resolve:
      with:
        - provider: exec
          inputs:
            command: git
            args: [describe, --abbrev=0, --tags]
    transform:
      with:
        - provider: cel
          inputs:
            expression: >-
              __self.exitCode == 0 ? __self.stdout.trim() : "0.0.1-alpha"
~~~

## Pattern: Directory Read, Render, Write (Template Pipeline)

The canonical pattern for file scaffolding. Three steps:

1. **directory** (list): read template files with content
2. **go-template** (render-tree): render all entries with shared data
3. **file** (write-tree): write rendered entries, optionally renaming

~~~yaml
resolvers:
  templateFiles:
    description: Read all .tpl files from template directory
    type: any
    resolve:
      with:
        - provider: directory
          inputs:
            operation: list
            path: ./scafctl/templates
            recursive: true
            filterGlob: "*.tpl"
            includeContent: true

  rendered:
    description: Render templates with project data
    type: any
    dependsOn: [templateFiles, projectName]
    resolve:
      with:
        - provider: go-template
          inputs:
            operation: render-tree
            entries:
              expr: '_.templateFiles.entries'
            data:
              expr: '{"projectName": _.projectName}'

# In workflow.actions:
actions:
  write-rendered:
    description: Write rendered files, stripping .tpl extension
    provider: file
    inputs:
      operation: write-tree
      basePath: "."
      entries:
        rslvr: rendered
      outputPath: >-
        {{ if .__fileDir }}{{ .__fileDir }}/{{ end }}{{ .__fileStem }}
~~~

Key points:
- Use `expr:` (not `rslvr:`) to access sub-keys like `_.templateFiles.entries`
- The `data` input for render-tree must be a map -- build it with a CEL object literal
- `outputPath` is a Go template for renaming; use `.__fileStem` to strip `.tpl`
- **External .tpl files need explicit dependsOn**: The DAG auto-detects
  resolver references in `expr:`, `rslvr:`, and inline `tmpl:`, but it
  cannot see references inside external `.tpl` files. If a template file
  uses `{{ .myResolver }}`, the `rendered` resolver must list `myResolver`
  in `dependsOn` -- otherwise it resolves to `<no value>`. List ALL
  resolvers referenced in template files in the `data` map AND in
  `dependsOn`.

## Pattern: Static Files (Copy As-Is)

Copy files without rendering, filtering by content existence.

~~~yaml
resolvers:
  staticFiles:
    type: any
    resolve:
      with:
        - provider: directory
          inputs:
            operation: list
            path: ./scafctl/static
            recursive: true
            includeContent: true
            filesOnly: true

actions:
  write-static:
    provider: file
    inputs:
      operation: write-tree
      basePath: "."
      entries:
        expr: '_.staticFiles.entries'
~~~

Use `filesOnly: true` on the directory resolver to exclude directory entries
(which have no content). This is cleaner than filtering with `has(e.content)`.

## Pattern: Conditional Actions with Task Map

Use a static resolver to map task names to action sets. Each action checks if it should run. This replaces traditional task runners.

~~~yaml
resolvers:
  task:
    resolve:
      with:
        - provider: parameter
          inputs:
            key: task
    validate:
      with:
        - provider: validation
          inputs:
            failWhen: '__self not in ["lint", "test", "build"]'

  taskActions:
    resolve:
      with:
        - provider: static
          inputs:
            value:
              lint: [lint]
              test: [lint, test]
              build: [lint, test, build]

actions:
  lint:
    when:
      expr: '_.taskActions[_.task].exists(t, t == "lint")'
    provider: exec
    inputs:
      command: scafctl
      args: [lint, solution, -f, ./scafctl/solution.yaml]

  test:
    when:
      expr: '_.taskActions[_.task].exists(t, t == "test")'
    provider: exec
    inputs:
      command: scafctl
      args: [test, functional, -f, ./scafctl/solution.yaml]
~~~

This gives you task dependencies (test includes lint) without explicit `dependsOn` chains.

## Pattern: Cross-Resolver Validation

Validate relationships between multiple resolver values. Use a dedicated resolver that depends on the inputs.

~~~yaml
resolvers:
  version:
    resolve:
      with:
        - provider: parameter
          inputs:
            key: version
        - provider: static
          inputs:
            value: ""

  task:
    resolve:
      with:
        - provider: parameter
          inputs:
            key: task

  versionRequired:
    description: Ensure version is set for tasks that need it
    when:
      expr: '_.task in ["build", "publish"]'
    resolve:
      with:
        - provider: static
          inputs:
            value: true
    validate:
      with:
        - provider: validation
          inputs:
            failWhen: '_.version == ""'
          message: "Version is required for build/publish tasks"
~~~

## Pattern: Dual-Mode Solution (Full vs Partial)

A single solution that behaves differently based on input. Use empty-string parameters and `when` clauses on actions.

~~~yaml
resolvers:
  name:
    resolve:
      with:
        - provider: parameter
          inputs:
            key: name
        - provider: static
          inputs:
            value: ""

actions:
  full-scaffold:
    when:
      expr: '_.name != ""'
    description: Full scaffolding when name is provided
    provider: file
    inputs:
      operation: write-tree
      basePath: "."
      entries:
        expr: '_.staticFiles.entries'

  partial-sync:
    when:
      expr: '_.name == ""'
    description: Sync only shared files when no name given
    provider: file
    inputs:
      operation: write-tree
      basePath: "."
      entries:
        expr: '_.staticFiles.entries'
~~~

## Pattern: Message Output

Display formatted results to the user. Use CEL for dynamic messages or Go templates for complex formatting.

~~~yaml
actions:
  info:
    provider: message
    inputs:
      type: info
      message:
        tmpl: |
          Solution:  {{ .solutionMeta.solution.name }}
          Version:   {{ .solutionMeta.solution.version }}
          Branch:    {{ .gitBranch }}

  success-summary:
    provider: message
    inputs:
      type: success
      message:
        expr: >-
          "Created " + string(size(_.rendered)) + " files:\n"
          + _.rendered.map(e, "  - " + e.path).join("\n")
~~~

Use `tmpl:` for multi-line human-readable output. Use `expr:` when you need list operations (map, join, filter).

## Pattern: Action Results with `__actions`

Report actual results from upstream actions instead of re-deriving from resolver data. This shows what actually happened (created, skipped, unchanged) rather than what was intended.

~~~yaml
actions:
  write-files:
    provider: file
    inputs:
      operation: write-tree
      basePath: "./output"
      entries:
        rslvr: rendered
      outputPath: >-
        {{ if .__fileDir }}{{ .__fileDir }}/{{ end }}{{ .__fileStem }}

  summary:
    dependsOn: [write-files]
    provider: message
    inputs:
      type: success
      message:
        tmpl: |
          Done! {{ index .__actions "write-files" "results" "filesWritten" }} files written.

          {{ range (index .__actions "write-files" "results" "filesStatus") -}}
            - {{ .path }} ({{ .status }})
          {{ end }}
~~~

The `write-tree` provider returns structured results:
- `filesWritten`, `created`, `overwritten`, `skipped`, `unchanged` (counts)
- `paths` (list of output paths)
- `filesStatus` (list of `{path, status}` per file)
- `success` (bool)

In CEL, use `__actions["action-name"].results` to access these fields. In Go templates, use `index .__actions "action-name" "results" "field"`.

Key points:
- Always prefer `__actions` over reconstructing file lists from resolver data
- `__actions` requires explicit `dependsOn` (the DAG does not auto-detect `__actions` references)
- Use `index` for action names with hyphens -- both CEL and Go templates need bracket/index syntax
- **Known limitation**: `__actions` only works in `expr:` (CEL), NOT in `tmpl:` (Go templates). Go templates are evaluated at graph-build time before actions run. Use `expr:` for action inputs that need `__actions`.

## Pattern: File Composition with `compose`

Split large solutions into focused files. The main solution composes in test definitions or logical sections.

~~~yaml
# solution.yaml
compose:
  - tests.yaml

spec:
  resolvers:
    # ... solution resolvers ...
~~~

~~~yaml
# tests.yaml -- merged into solution.yaml at load time
spec:
  testing:
    config:
      files: [templates/, static/]  # shared by all tests
    cases:
      _base:
        command: [run, resolver]
        args: [-o, json]
      lint:
        description: Solution lints cleanly
        command: [lint]
        exitCode: 0
      smoke:
        extends: [_base]
        description: Resolvers execute with defaults
        exitCode: 0
~~~

Keep tests in `tests.yaml` and compose them in. Use `config.files` for shared files and template cases (`_` prefix) with `extends` to avoid duplication. Files in `bundle.include` are auto-copied to test sandboxes. For very large solutions, you can compose resolver groups or action groups from separate files.

## Anti-Patterns

- **Resolver doing too much**: If a resolver has 3+ transforms, split into separate resolvers
- **Complex CEL in inputs**: If an `expr:` value exceeds ~80 chars, extract to a dedicated resolver with a clear name
- **Missing `type: any`**: Directory and HTTP providers return objects -- omit `type` or use `type: any`
- **Inline tests**: Tests belong in `tests.yaml`, not in `solution.yaml`
- **`dependsOn` everywhere**: Most dependencies are auto-detected from `rslvr:`, `expr:`, and `tmpl:` references. Only add explicit `dependsOn` when there is no data reference (e.g., backup action before write action)
