---
applyTo: "scafctl/**/*.yaml"
---

# CEL Expression Conventions

CEL (Common Expression Language) is used in resolver inputs, `when` clauses, and action inputs via the `expr:` prefix.

## When to Use CEL vs Go Templates

| Use Case | Use | Why |
|----------|-----|-----|
| Typed values (numbers, booleans, arrays, objects) | `expr:` | CEL preserves types |
| Filtering or transforming lists | `expr:` | CEL has list comprehensions |
| Conditional logic (`when` clauses) | `expr:` | `when` requires CEL |
| String rendering with multiple variables | `tmpl:` | Go templates are cleaner for strings |
| Multi-line string output | `tmpl:` | CEL string concatenation is cumbersome |
| Simple resolver reference (whole output) | `rslvr:` | No expression needed -- does NOT support dotted sub-paths |

## Context Variables

- `_` -- Map of resolved resolver values (e.g., `_.environment`, `_.config.port`)
- `__self` -- Current resolver's own value (available in `transform` and `validate` phases)
- `__plan` -- Pre-execution resolver topology (available in resolvers)
- `__execution` -- Resolver execution metadata (available in actions)
- `__actions` -- Upstream action results (available in actions, keyed by action name)

### `__actions` in Actions

Actions that depend on other actions can access their results via `__actions`. Each entry contains `status`, `results`, `inputs`, `startTime`, and `endTime`.

~~~yaml
# Access write-tree results (files written, status, counts)
show-results:
  dependsOn: [write-files]
  provider: message
  inputs:
    type: success
    message:
      expr: >
        "Wrote " + string(__actions["write-files"].results.filesWritten) + " files"

# Conditional on upstream action status
notify:
  dependsOn: [deploy]
  when:
    expr: '__actions["deploy"].status == "succeeded"'
  provider: message
  inputs:
    type: success
    message:
      expr: '"Deploy completed successfully"'

# Access full write-tree results as JSON
debug-output:
  dependsOn: [write-files]
  provider: message
  inputs:
    type: info
    message:
      expr: 'json.marshalPretty(__actions["write-files"].results)'
~~~

The `write-tree` provider returns:
- `filesWritten` (int) -- total files written
- `created` (int) -- new files
- `overwritten` (int) -- replaced files
- `skipped` (int) -- skipped files
- `unchanged` (int) -- unchanged files
- `paths` (list) -- list of output file paths
- `filesStatus` (list) -- `[{path, status}]` for each file
- `success` (bool)

Note: Use `index` syntax for action names with hyphens -- `__actions["write-files"]`, not `__actions.write-files` (CEL parses hyphens as subtraction).

Both `expr:` (CEL) and `tmpl:` (Go templates) have full access to `__actions` on action inputs.

### `__self` in Transform and Validate

In the `transform` phase, `__self` is the value produced by `resolve` (or the previous transform step). In the `validate` phase, `__self` is the final resolved+transformed value.

~~~yaml
# Transform: __self is the current value being transformed
transform:
  with:
    - provider: cel
      inputs:
        expression: "__self.trim()"
    - provider: cel
      inputs:
        expression: '__self.startsWith("v") ? __self.substring(1) : __self'

# Validate: __self is the final value; _ gives access to other resolvers
validate:
  with:
    - provider: validation
      inputs:
        failWhen: 'size(__self) < 3 || size(__self) > 60'
      message: "Must be 3-60 characters"
    - provider: validation
      inputs:
        failWhen: '_.task in ["build"] && __self == ""'
      message: "Required for build task"
~~~

## Common Functions

~~~yaml
# String operations
expr: "'hello'.upperAscii()"
expr: "'hello world'.split(' ')"
expr: "_.name.matches('^[a-z]+')"
expr: "_.name.contains('prod')"
expr: "_.name.startsWith('env-')"
expr: "' hello '.trim()"   # trim whitespace (NOT trimSpace)
expr: "_.value.trim()"     # common for exec provider stdout

# List operations
expr: "_.items.filter(x, x.enabled)"
expr: "_.items.map(x, x.name)"
expr: "_.items.exists(x, x.status == 'ready')"
expr: "_.items.size()"

# Map operations
expr: "has(_.config.optional_field)"
expr: "_.config.?optional_field.orValue('default')"
expr: "map.merge(_.defaults, _.overrides)"      # merge two maps (second wins)
expr: "map.add(_.config, 'newKey', 'value')"     # add key-value pair
expr: "map.select(_.config, ['key1', 'key2'])"   # keep only specified keys
expr: "map.omit(_.config, ['secret'])"            # remove specified keys

# JSON / YAML parsing and serialization
expr: "json.unmarshal(_.execResult)"             # parse JSON string to object
expr: "json.marshal(_.config)"                    # serialize to compact JSON
expr: "json.marshalPretty(_.config)"              # serialize to pretty JSON
expr: "yaml.unmarshal(_.fileContent)"             # parse YAML string to object
expr: "yaml.marshal(_.config)"                    # serialize to YAML string

# Base64 encoding/decoding
expr: "base64.encode(bytes(_.value))"             # string -> bytes -> base64
expr: "string(base64.decode(_.encoded))"          # base64 -> bytes -> string

# Regex
expr: "regex.match('^v[0-9]', _.tag)"             # test if pattern matches
expr: "regex.replace(_.input, '[^a-z]', '')"      # replace all matches
expr: "regex.findAll('[0-9]+', _.text)"            # find all matches as list
expr: "regex.split('\\s+', _.line)"               # split by pattern

# Ternary
expr: "_.env == 'prod' ? 'us-east1' : 'us-central1'"

# Type coercion
expr: "int(_.port)"
expr: "string(_.count)"
~~~

## Official CEL Extensions

The engine loads the official cel-go extension libraries. These provide
additional functions beyond core CEL. Users often miss these because the
function names differ from what they expect.

### Math (`math.greatest` / `math.least`)

Use `math.greatest()` and `math.least()` -- NOT `max()` / `min()`
/ `math.max()` / `math.min()` (those do not exist).

~~~yaml
# Two-argument form
expr: "math.greatest(size(_.label), 20)"     # max of two values
expr: "math.least(_.timeout, 300)"           # min of two values

# List form -- find max/min in a list
expr: "math.greatest(_.scores)"              # max of list
expr: "math.least(_.scores)"                 # min of list
expr: "math.greatest([3, 7, 1])"             # returns 9
~~~

### Strings (split, substring, etc.)

~~~yaml
expr: "'a,b,c'.split(',')"                   # ["a", "b", "c"]
expr: "'hello'.charAt(1)"                    # "e"
expr: "'hello'.substring(1, 3)"              # "el"
expr: "'hello'.upperAscii()"                 # "HELLO"
expr: "'HELLO'.lowerAscii()"                 # "hello"
expr: "'hello'.indexOf('ll')"                # 2
expr: "'hello'.replace('l', 'r')"            # "herro"
~~~

### Lists (distinct, flatten, etc.)

~~~yaml
expr: "[1, 2, 2, 3].distinct()"              # [1, 2, 3]
expr: "[[1,2],[3,4]].flatten()"              # [1, 2, 3, 4]
expr: "[3, 1, 2].sort()"                     # [1, 2, 3]
expr: "[3, 1, 2].sortBy(x, x)"              # [1, 2, 3]
expr: "_.items.sortBy(x, x.name)"            # sort objects by field
~~~

### Sets (contains, intersects, equivalent)

~~~yaml
expr: "sets.contains([1,2,3], [2,3])"        # true -- subset check
expr: "sets.intersects([1,2], [3,4])"         # false -- any overlap?
expr: "sets.equivalent([1,2], [2,1])"         # true -- same elements?
~~~

### Not Available

These functions do NOT exist in the CEL environment:

- `max()` / `min()` -- use `math.greatest()` / `math.least()`
- `"x".repeat(n)` -- use Go templates with sprig `repeat` instead
- `reduce()` / `fold()` -- use resolver chains for accumulation
- `trimSpace()` -- use `trim()`
- `fromJSON()` / `parseJSON()` -- use `json.unmarshal()`

## Resolver References in CEL

Access resolver outputs with `_.resolverName`:

~~~yaml
# Whole resolver output
expr: "_.myResolver"

# Sub-key access (use this instead of rslvr: with dotted paths)
expr: "_.httpResponse.body"
expr: "_.directoryListing.entries"
~~~

Important: The `rslvr:` syntax does not support dotted sub-path access. Use `expr:` to access nested fields.

Note: All of these reference styles (`rslvr:`, `expr:` with `_.name`, `tmpl:` with `._.name`) are tracked by the DAG for automatic dependency ordering. You rarely need explicit `dependsOn`.

## Common Pitfalls

- **Wrong type coercion**: Never set `type: string` on resolvers returning objects (e.g., `http`, `directory`). Omit `type` when unsure.
- **Function naming**: CEL uses `trim()` not `trimSpace()`, `json.unmarshal()` not `fromJSON()`, `math.greatest()` not `max()`. See "Official CEL Extensions" above for correct names.
- **Missing `has()` check**: Use `has(_.config.field)` before accessing optional fields to avoid runtime errors.
- **Overly complex expressions**: If an expression needs multiple lines or nested ternaries, split into separate resolvers or use `when` clauses instead.
- **String building in CEL**: Use Go templates (`tmpl:`) for multi-line strings. CEL string concatenation becomes unreadable quickly.
- **`json.unmarshal` takes a string, not bytes**: Use `json.unmarshal(_.myResolver)`, not `json.unmarshal(b"...")`. CEL bytes syntax is not needed.
- **Accessing `__actions` with hyphens**: Use `__actions["my-action"]` not `__actions.my-action` -- CEL interprets hyphens as subtraction.
- **`string()` on maps**: Use `json.marshal()` to serialize maps/objects to strings in CEL. `string(map)` fails with "no such overload".
- **List concatenation**: Use `+` to concatenate lists (`list1 + list2`). There is no `.concat()` method -- that is JavaScript, not CEL.
- **JSON null fields**: HTTP API responses often contain null fields. Always null-guard before accessing: `_.api.field != null ? string(_.api.field) : ""`. Calling `string(null)` or comparing `null == "value"` fails with "no such overload".
- **Numeric ID comparisons**: JSON numbers from APIs may parse as int or double. When comparing to a string parameter, coerce explicitly: `string(int(_.api.id)) == _.paramId`. Or set `type: string` on the parameter resolver.

## Debugging

- **List all available functions**: Run `scafctl get cel-functions` to see
  every CEL function registered in the engine, grouped by extension. Always
  check this before assuming a function is missing.
- Use `scafctl eval cel --expression '...'` to test expressions interactively
- Use `validate_expression` to syntax-check CEL without executing
- Use `evaluate_cel` to test CEL with sample data
- Use `extract_resolver_refs` to find `_.resolverName` references in expressions
