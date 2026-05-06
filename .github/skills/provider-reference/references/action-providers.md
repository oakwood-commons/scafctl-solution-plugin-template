# Action Providers

## file (action)

Write files and file trees. The most common action provider.

~~~yaml
# Write a single file
actions:
  write-config:
    provider: file
    inputs:
      operation: write
      path: "./output/config.yaml"
      content: {rslvr: renderedConfig}
      createDirs: true

  # Write a tree of files
  write-rendered:
    provider: file
    inputs:
      operation: write-tree
      basePath: "."
      entries: {rslvr: rendered}
      outputPath: >-
        {{ if .__fileDir }}{{ .__fileDir }}/{{ end }}{{ .__fileStem }}
~~~

Operations: `write`, `write-tree`, `read`, `exists`, `delete`.

## exec (action)

Run external commands as side-effects.

~~~yaml
actions:
  run-lint:
    provider: exec
    inputs:
      command: scafctl lint -f ./scafctl/solution.yaml
      # args: [--verbose]
      # workingDir: "./subdir"
      # env: {KEY: "value"}
      # timeout: 30
      # shell: auto
~~~

**Output**: Returns `{command, exitCode, shell, stderr, stdout, success}`.

## go-template (action)

Batch-render a tree of template entries. Used in the directory-render-write pipeline.

~~~yaml
actions:
  render-templates:
    provider: go-template
    inputs:
      operation: render-tree
      entries: {expr: '_.templateFiles.entries'}
      data: {expr: '{"name": _.projectName}'}
      # missingKey: error | zero | invalid
~~~

## directory (action)

Directory operations: create, remove, copy, list. The same provider also supports resolver-side `operation: list`; see `data-providers.md` when you need to enumerate files before actions run.

~~~yaml
actions:
  create-output:
    provider: directory
    inputs:
      operation: mkdir
      path: ./output/reports
      createDirs: true
  # Also: copy, rmdir, list
~~~

## message (action)

Display styled terminal messages or render structured data.

~~~yaml
# Text mode
actions:
  success:
    provider: message
    inputs:
      message: "Deployment complete!"
      type: success          # success | warning | error | info | debug | plain
      # label: "step 2/5"
      # destination: stdout

  # Data mode -- render structured data as tables, trees, cards
  show-results:
    provider: message
    inputs:
      data:
        rslvr: myDataResolver
      format: auto             # auto | table | list | tree | mermaid | json | yaml | quiet
      # label: "Results"
      # columnOrder: [name, status, env]
      # columnHints:
      #   properties:
      #     name:
      #       x-kvx-header: "Full Name"
      #     metadata:
      #       x-kvx-visible: false
      # display:                             # Rich card-list/detail views
      #   collectionTitle: "Projects"
      #   list:
      #     titleField: name
      #     subtitleField: type
      #     badgeFields: [env]
      #   detail:
      #     titleField: name
      #     sections:
      #       - title: Identity
      #         fields: [name, id]
      # expand: true
~~~

**Text vs Data**: `message` and `data` are mutually exclusive. Use `message` for styled text, `data` for structured rendering.
