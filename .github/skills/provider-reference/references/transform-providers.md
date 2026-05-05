# Transform & Validation Providers

## cel (transform)

CEL expression evaluation. Access current value via `__self`.

~~~yaml
transform:
  with:
    - provider: cel
      inputs:
        expression: "__self.trim().lowerAscii()"
~~~

## go-template (transform)

Go template rendering. Access current value via `.`. Capabilities: `transform`, `action`.

~~~yaml
transform:
  with:
    - provider: go-template
      inputs:
        template: "prefix-{{ . }}-suffix"
~~~

## validation

Rule-based validation with CEL expressions. Access current value via `__self`.

~~~yaml
validate:
  with:
    - provider: validation
      inputs:
        failWhen: "size(__self) < 3 || size(__self) > 60"
        message: "Name must be 3-60 characters"
~~~

Multiple rules:

~~~yaml
validate:
  with:
    - provider: validation
      inputs:
        rules:
          - failWhen: "size(__self) == 0"
            message: "Must not be empty"
          - failWhen: "!__self.matches('^[a-z][a-z0-9-]*$')"
            message: "Must be DNS-safe (lowercase, hyphens, start with letter)"
~~~