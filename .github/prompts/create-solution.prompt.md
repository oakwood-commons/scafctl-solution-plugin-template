---
description: "scafctl: Create a new solution from a description -- scaffold YAML, templates, validate, and present run command"
agent: "solution-author"
tools:
  - scafctl/*
argument-hint: "Describe what the solution should do (e.g., 'scaffold a Go microservice with Dockerfile and CI pipeline')"
---

Create a new scafctl solution based on the user's description.

The solution lives at `./scafctl/solution.yaml` in the root of the scafctl directory. Supporting files:
- `./scafctl/templates/` -- Go templates rendered with resolver data (`.tpl` extension stripped on output)
- `./scafctl/static/` -- static files copied as-is (optional)

## Workflow

1. **Gather requirements** -- Ask what the solution should do, what inputs it needs, and what it should produce. Keep it to 1-2 questions.
2. Call `get_solution_schema` to get the full JSON Schema
3. Call `list_providers` to see available providers
4. For each provider needed, call `get_provider_schema` to verify exact field names
5. Call `get_example` with path "solutions/email-notifier/solution.yaml" for a practical reference
6. Write `./scafctl/solution.yaml` following the schema
7. Place any Go templates in `./scafctl/templates/`
8. Place any static files in `./scafctl/static/`
9. Call `lint_solution` to validate the result
10. If the solution contains CEL expressions or Go templates, call `validate_expressions` to verify syntax
11. Present the final solution with the correct run command:
    - Has `spec.workflow.actions`: `scafctl run solution -f ./scafctl/solution.yaml -r key=value`
    - Resolver-only (no workflow): `scafctl run resolver -f ./scafctl/solution.yaml key=value`

## Rules

- Always prefix relative file paths with "./" in your response
- Follow the CEL vs Go template and design pattern rules from the solution-author agent
- Never guess provider field names -- always call `get_provider_schema`
- The user can also scaffold a solution from the CLI with `scafctl new solution <name>`
