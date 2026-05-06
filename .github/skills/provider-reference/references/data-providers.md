# Data Source Providers (capability: from)

## parameter

Access CLI parameters passed via `-r`/`--resolver` flags. Use the static provider's fallback chain for defaults.

~~~yaml
resolve:
  with:
    - provider: parameter
      inputs:
        key: projectName       # Matches -r projectName=value
    - provider: static          # Fallback default
      inputs:
        value: "my-project"
~~~

**Input**: `key` (required) -- name of the parameter to retrieve.

**Output**: The parameter value, auto-typed (strings, numbers, booleans, arrays from comma-separated values).

## env

Read, set, list, or unset environment variables.

~~~yaml
resolve:
  with:
    - provider: env
      inputs:
        operation: get             # get | set | list | unset
        name: MY_ENV_VAR
        # default: "fallback"      # Default if not set (get only)
        # raw: true                 # Return just the value string (default: false)
        # prefix: "AWS_"           # Filter by prefix (list only)
        # value: "new-value"       # Value to set (set only)
~~~

## static

Pass-through literal values. Useful with `when` clauses for conditional static values.

~~~yaml
resolve:
  with:
    - provider: static
      inputs:
        value: "any literal value"
        # value: {expr: "_.computed"}    # Can use ValueRef
        # value: [1, 2, 3]              # Arrays
        # value: {key: value}           # Objects
~~~

## file

Read file contents.

~~~yaml
resolve:
  with:
    - provider: file
      inputs:
        path: "./config.json"
        # encoding: utf-8 | base64 | binary
        # parse: json | yaml | toml      # Auto-parse into object
~~~

## exec

Run commands using an embedded cross-platform POSIX shell. Pipes, redirections, and variable expansion work on all platforms without external shell binaries. Capabilities: `from`, `transform`, `action`.

~~~yaml
resolve:
  with:
    - provider: exec
      inputs:
        command: "echo hello | tr a-z A-Z"
        # args: ["arg1", "arg2"]          # Auto-quoted arguments
        # workingDir: "./subdir"
        # env: {KEY: "value"}
        # raw: true                         # Return just trimmed stdout (default: false)
        # stdin: "input data"
        # timeout: 30                      # Seconds (integer)
        # shell: auto                      # auto | sh | bash | pwsh | cmd
        # passthrough: true                # Stream output to terminal in real-time
~~~

**Shell options**: `auto`/`sh` (embedded POSIX, default -- works everywhere), `bash` (external), `pwsh` (PowerShell Core), `cmd` (Windows cmd.exe).

**Output**: In `from`/`transform` mode returns the full `{stdout, stderr, exitCode}` object by default. Set `raw: true` to get just the trimmed stdout string. In `action` mode always returns `{command, exitCode, shell, stderr, stdout, success}`.

## http

HTTP requests. Returns an object with `statusCode`, `body`, `headers`.

~~~yaml
resolve:
  with:
    - provider: http
      inputs:
        url: "https://api.example.com/data"
        method: GET
        # headers: {Authorization: "Bearer token"}
        # body: '{"key": "value"}'
        # timeout: 30                      # Seconds (integer)
        # autoParseJson: true              # Parse JSON response into object
        # authProvider: entra              # Built-in auth (entra, github)
        # scope: "api://.../.default"      # OAuth scope for entra
        # retry: {}                        # Retry config for transient failures
        # poll: {}                         # Poll until condition met
        # pagination: {}                   # Follow paginated responses
~~~

**Important**: Returns an object -- never set `type: string` on the resolver. Access fields via `expr: "_.httpResolver.body"`.

## git

Git version control operations on local and remote repositories. Capabilities: `from`, `action`.

~~~yaml
# Clone a repository
resolve:
  with:
    - provider: git
      inputs:
        operation: clone
        repository: "https://github.com/user/repo.git"
        path: /tmp/repo
        # depth: 1              # Shallow clone
        # branch: main

# Get repo status
resolve:
  with:
    - provider: git
      inputs:
        operation: status
        path: ./my-repo
~~~

**Operations**: `clone`, `pull`, `status`, `add`, `commit`, `push`, `checkout`, `branch`, `log`, `tag`

**Key fields**: `path` (repo location), `repository` (URL for clone), `branch`, `message` (for commit), `files` (for add/commit), `remote` (default: origin), `force`, `tag`, `depth` (shallow clone).

## directory

List directory contents during resolver execution. This is commonly used to gather template or static file trees before rendering or writing them.

~~~yaml
resolve:
  with:
    - provider: directory
      inputs:
        operation: list
        path: "./scafctl/templates"
        # recursive: true
        # includeContent: false
        # filesOnly: true
        # filterGlob: "**/*.tpl"
~~~

**Common operations in resolvers**: `list`

**Useful fields**: `path`, `recursive`, `includeContent`, `filesOnly`, `filterGlob`, `maxDepth`.

**Output**: Returns an object with listing metadata plus `entries`. Access files via `expr: "_.templateFiles.entries"`.

## secret

Retrieve encrypted secrets from the scafctl secrets store.

~~~yaml
resolve:
  with:
    - provider: secret
      inputs:
        operation: get             # get | list
        name: "my-secret-key"
        # required: true            # Error if not found (default: false)
        # fallback: "default"      # Value when not found and required=false
        # pattern: "^prod-.+$"     # Regex match instead of exact name
~~~

Mark the resolver as `sensitive: true` when using this provider.

## identity

Authentication identity information (claims, status, groups) from auth handlers.

~~~yaml
resolve:
  with:
    - provider: identity
      inputs:
        operation: claims          # status | claims | groups | list
        # handler: entra           # Auth handler to query
        # scope: "api://.../.default"
~~~

**Output**: Returns `{authenticated, handler, identityType, claims, ...}`. Access via `expr: "_.identity.claims"`.

## metadata

Returns runtime metadata about the scafctl process and current solution. No inputs required.

~~~yaml
resolve:
  with:
    - provider: metadata
      inputs: {}
~~~

**Output**: Returns `{args, command, cwd, entrypoint, solution, version}`. Access fields via `expr: "_.meta.solution.name"`.

## solution

Cross-solution references (run another solution as a data source).

~~~yaml
resolve:
  with:
    - provider: solution
      inputs:
        path: "./other-solution.yaml"
        # inputs: {key: "value"}
~~~

## debug

Inspect resolver data during workflow execution.

~~~yaml
resolve:
  with:
    - provider: debug
      inputs:
        label: "Debug checkpoint"
        # format: json              # json | yaml | text
        # expression: "_.myResolver"
        # destination: stdout       # stdout | stderr | file
        # file: "./debug.json"
        # colorize: true
~~~

## sleep

Delay execution (useful for rate limiting).

~~~yaml
resolve:
  with:
    - provider: sleep
      inputs:
        duration: "2s"
~~~
