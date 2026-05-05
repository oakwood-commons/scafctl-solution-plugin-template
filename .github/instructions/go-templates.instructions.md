---
applyTo: "scafctl/templates/**/*.tpl"
---

# Go Template Conventions

Templates in `scafctl/templates/` are processed by the `go-template` provider via `render-tree`.

## File Naming

- Use `.tpl` extension on all template files (e.g., `README.md.tpl`, `Dockerfile.tpl`)
- The `.tpl` extension is stripped on output (`README.md.tpl` becomes `README.md`)

## Data Access

- Resolver values are available via `{{ .resolverName }}`
- Nested fields: `{{ .resolverName.field }}`
- Additional data passed via `data` input: `{{ .customKey }}`

**CRITICAL: Do NOT use `{{ ._.resolverName }}`** -- the `_` map is a CEL
convention only. In Go templates, resolver values are at the root context.
`{{ ._.x }}` silently produces `<no value>` with no error.

| Context | CEL (`expr:`) | Go template (`tmpl:`) |
|---------|---------------|----------------------|
| Resolver value | `_.resolverName` | `{{ .resolverName }}` |
| Nested field | `_.resolver.field` | `{{ .resolver.field }}` |
| Self (transform) | `__self` | `{{ .__self }}` |
- In **action** inputs (`tmpl:` on actions), `__`-prefixed context variables are also available:
  - `{{ .__actions }}` -- results of upstream actions (keyed by action name)
  - `{{ .__execution }}` -- resolver execution metadata
  - `{{ .__cwd }}` -- working directory
- Built-in variables from `render-tree`:
  - `{{ .filePath }}` -- full relative path of the source file
  - `{{ .fileName }}` -- filename with extension
  - `{{ .fileStem }}` -- filename without extension (and without `.tpl`)
  - `{{ .fileDir }}` -- directory portion of the path
  - `{{ .fileExt }}` -- file extension

### Accessing `__actions` in Go Templates

When an action depends on other actions, their results are accessible via `.__actions`:

~~~tpl
{{/* List files written by a write-tree action */}}
Files created:
{{ range (index .__actions "write-files" "results" "filesStatus") -}}
  - {{ .path }} ({{ .status }})
{{ end -}}

{{/* Show count of files written */}}
Wrote {{ index .__actions "write-files" "results" "filesWritten" }} files.

{{/* Check upstream action status */}}
{{ if eq (index .__actions "deploy" "status") "succeeded" -}}
Deploy succeeded!
{{- end }}
~~~

Note: Use the `index` function for action names containing hyphens. `.__actions.write-files` does not work because Go templates interpret the hyphen as subtraction.

## Core Syntax

~~~tpl
{{/* Variable interpolation */}}
Name: {{ .projectName }}

{{/* Conditionals */}}
{{ if .enableMonitoring -}}
monitoring:
  enabled: true
{{- end }}

{{/* Negation */}}
{{ if not .disableLogging -}}
logging: true
{{- end }}

{{/* Comparison */}}
{{ if eq .environment "prod" -}}
replicas: 3
{{- else -}}
replicas: 1
{{- end }}

{{/* Range over lists */}}
{{ range .servers -}}
- name: {{ .name }}
  host: {{ .host }}
{{ end -}}

{{/* Range with index */}}
{{ range $i, $item := .items -}}
{{ $i }}: {{ $item }}
{{ end -}}

{{/* Range over maps */}}
{{ range $key, $value := .labels -}}
{{ $key }}: {{ $value }}
{{ end -}}
~~~

## Whitespace Control

Use `{{-` and `-}}` trim markers to remove whitespace around template actions:

- `{{- ` trims whitespace (including newlines) **before** the action
- ` -}}` trims whitespace (including newlines) **after** the action
- Combine both: `{{- action -}}` trims on both sides

~~~tpl
{{/* Without trim markers -- produces blank lines */}}
{{ if .debug }}
debug: true
{{ end }}

{{/* With trim markers -- no extra blank lines */}}
{{ if .debug -}}
debug: true
{{- end }}
~~~

## Sprig Functions

Go templates in scafctl include [sprig](https://masterminds.github.io/sprig/) functions:

**Math limitation:** Go templates have NO built-in arithmetic operators or
math functions like `divCeil`, `div`, `mod`, or `ceil`. For any arithmetic
(division, rounding, pagination math), use a CEL resolver instead and
reference the result in the template. Sprig provides `add`, `sub`, `mul`,
`div`, `mod` as functions (e.g., `{{ div .total .pageSize }}`).

~~~tpl
{{/* String functions */}}
{{ .name | lower }}
{{ .name | upper }}
{{ .name | title }}
{{ .name | trim }}
{{ .name | replace "old" "new" }}
{{ .name | contains "sub" }}
{{ .name | hasPrefix "pre" }}
{{ .name | hasSuffix "suf" }}
{{ .path | dir }}
{{ .path | base }}

{{/* Default values */}}
{{ .optional | default "fallback" }}

{{/* List functions */}}
{{ .items | join ", " }}
{{ .items | first }}
{{ .items | last }}
{{ .items | has "value" }}

{{/* Type conversion */}}
{{ .count | toString }}
{{ .port | int }}
{{ .enabled | ternary "yes" "no" }}

{{/* Indentation (useful for YAML/JSON nesting) */}}
{{ .block | nindent 4 }}
{{ .block | indent 2 }}
~~~

## Best Practices

- Use Go templates for **text rendering only** -- not data logic
- Move filtering, conditionals for value selection, and data transformations into resolvers with `when`/`transform`
- Keep template logic simple: variable interpolation, `range` loops for lists, basic `if` for presentation
- For complex conditional content, prefer multiple templates with `when` on the action over `{{ if }}` blocks in a single template
- Use `{{- }}` and `{{ -}}` trim markers to control whitespace
- Use `{{ .value | nindent N }}` when inserting multi-line content into indented YAML

## Nil Safety

Go template built-ins like `len` panic on nil values. Always guard with
an existence check:

~~~tpl
{{/* WRONG -- panics if .items is nil */}}
{{ if eq (len .items) 0 }}empty{{ end }}

{{/* CORRECT -- nil-safe check */}}
{{ if not .items }}empty{{ end }}

{{/* CORRECT -- guard then use len */}}
{{ if .items }}{{ len .items }} items{{ else }}empty{{ end }}
~~~

## Avoid `{{ with }}` Blocks for Resolver Data

The dependency scanner inspects Go templates to detect resolver references
(`.resolverName`). Using `{{ with .someResolver }}` changes the dot context,
causing nested field accesses like `.fieldName` to be misinterpreted as
references to a resolver named `fieldName`. This produces false dependency
errors:

~~~text
resolver dependency error: summary depends on kubeNamespaces but
kubeNamespaces wasn't present
~~~

Workaround: use variable assignments instead of `{{ with }}`:

~~~tpl
{{/* WRONG -- triggers false dependency detection */}}
{{ with .platformAssets.body.data }}
  {{ .kubeNamespaces }}  {{/* scanner thinks this is a resolver reference */}}
{{ end }}

{{/* CORRECT -- use $var assignment */}}
{{ $d := .platformAssets.body.data }}
{{ $d.kubeNamespaces }}
~~~

This is a known scafctl limitation in the dependency scanner.

## Ignored Blocks

To pass through literal `{{ }}` syntax (e.g., Terraform, Helm), use ignored block markers:

~~~tpl
resource "aws_instance" "web" {
  name = "{{ .instanceName }}"
  /*scafctl:ignore:start*/
  for_each = { for k, v in var.items : k => v }
  /*scafctl:ignore:end*/
}
~~~

Configure the markers in the go-template provider inputs via `ignoredBlocks`.

### Custom Delimiters

When template files contain literal `{{ }}` syntax that cannot be wrapped in
ignored blocks (e.g., Tekton Pipelines-as-Code variables, Helm templates,
GitHub Actions expressions), use custom delimiters to avoid conflicts:

~~~yaml
# In the go-template render-tree action or resolver
provider: go-template
inputs:
  operation: render-tree
  entries:
    expr: '_.templateFiles.entries'
  data:
    expr: '{...}'
  leftDelim: "<%"
  rightDelim: "%>"
~~~

Then use `<%` and `%>` in template files instead of `{{` and `}}`:

~~~tpl
# Tekton PipelineRun with Go template variables
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: <% .appName %>-run
  annotations:
    # These are Pipelines-as-Code variables -- passed through literally
    pipelinesascode.tekton.dev/on-target-branch: "{{ target_branch }}"
    pipelinesascode.tekton.dev/on-event: "{{ event }}"
spec:
  params:
    - name: app-name
      value: <% .appName %>
~~~

Use custom delimiters when a file has **many** literal `{{ }}` occurrences.
For isolated cases, prefer `scafctl:ignore:start/end` markers instead.

## Anti-Patterns

- Do NOT use `{{ if }}` blocks to choose between different data values -- use resolver `when` clauses instead
- Do NOT build complex data structures in templates -- do it in a resolver `transform` phase
- Do NOT use `{{ printf }}` for data formatting -- use CEL expressions in resolvers
- Do NOT use `{{ .resolver.subkey }}` in `tmpl:` ValueRefs for optional fields without checking existence first -- use `expr:` with `has()` instead
