# HCL Provider

Process HCL/Terraform files: parse, format, validate, or generate. Capabilities: `from` and `transform`. (Beta)

## Operations

- `parse` (default) -- structured block extraction
- `format` -- canonical HCL formatting
- `validate` -- syntax checking
- `generate` -- produce HCL from structured data

## Input Sources (mutually exclusive)

`content`, `path`, `paths`, `dir`

## Examples

~~~yaml
# Parse a single .tf file
resolve:
  with:
    - provider: hcl
      inputs:
        path: ./main.tf

# Parse all .tf files in a directory (merged result)
resolve:
  with:
    - provider: hcl
      inputs:
        dir: ./terraform

# Parse inline HCL content
resolve:
  with:
    - provider: hcl
      inputs:
        content: |
          variable "region" {
            type    = string
            default = "us-east-1"
          }

# Format HCL
resolve:
  with:
    - provider: hcl
      inputs:
        operation: format
        path: ./main.tf
        # Returns: {formatted: "...", changed: true/false}

# Generate HCL from structured data
resolve:
  with:
    - provider: hcl
      inputs:
        operation: generate
        # output_format: hcl | json
        blocks:
          variables:
            - name: region
              type: string
              default: us-east-1
              description: "AWS region"
          resources:
            - type: aws_instance
              name: web
              attributes:
                ami: ami-12345
                instance_type: t3.micro

# As a transform -- parse HCL content from a previous resolver
transform:
  with:
    - provider: hcl
      inputs: {}
~~~

## Parse Output Shape

~~~yaml
variables: [{name, type, default, description, ...}]
resources: [{type, name, attributes, ...}]
data: [{type, name, attributes, ...}]
modules: [{name, source, ...}]
outputs: [{name, value, description, ...}]
locals: {key: value, ...}
providers: [{name, attributes, ...}]
terraform: {required_version, ...}
import: [...]
moved: [...]
check: [...]
~~~

**Important**: Never set `type: string` on resolvers using HCL parse -- it returns an object. Use `type: any` or omit `type`.