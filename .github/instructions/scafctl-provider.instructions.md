---
description: "Provider template guidance for scafctl plugins: lifecycle, schema design, WhatIf behavior, and test expectations."
applyTo: "scafctl/templates/**/*.tpl"
---

# scafctl Provider Template Guidance

Use this guidance when editing provider-related Go templates in this solution repository.

## Template Scope

This repository does not contain live Go provider code. It contains Go templates that generate provider repositories.

- Preserve placeholders such as `<% .name %>`, `<% .module %>`, `<% .provider_name %>`, `<% .description %>`, and `<% .capability_consts %>`.
- Keep template behavior aligned with the generated repository docs, prompts, and tests.
- When you change generated provider behavior, update the corresponding tests and any generated AI guidance in `scafctl/static/.github/`.

## Provider Responsibilities

A generated provider plugin should keep responsibilities separated:

- `cmd/<plugin-name>/main.go` should stay a thin entry point.
- `internal/.../provider.go` should own provider behavior.
- `GetProviderDescriptor` should describe the provider contract, not execute logic.
- `ExecuteProvider` should implement the real behavior.
- `DescribeWhatIf` should explain the same behavior without side effects.

## Descriptor Expectations

Generated descriptors should be predictable and accurate.

- Keep `Name`, `DisplayName`, `Description`, `Capabilities`, and `Schema` internally consistent.
- Do not claim capabilities that the generated implementation does not support.
- Keep schema examples and required fields synchronized with the implementation and README snippets.
- Prefer clear input names and stable output shapes.

## Execution Semantics

Generated provider code should follow these rules:

- Reject unknown provider names consistently.
- Handle nil, empty, and zero-value inputs deliberately.
- Keep side effects out of `DescribeWhatIf`.
- Return structured output that matches the documented contract.
- Avoid hidden global state.

## Optional Interface Methods

When editing template implementations of optional methods, keep their intent clear.

- `ConfigureProvider` stores host-provided configuration and should not do heavy work.
- `ExecuteProviderStream` should only be implemented when streaming is genuinely supported.
- `ExtractDependencies` should only return resolver dependencies when provider inputs actually reference them.
- `StopProvider` should be safe to call repeatedly.

## Test Expectations

Generated provider tests should cover at least:

- known provider vs unknown provider
- happy path execution
- nil or empty input handling
- `DescribeWhatIf` parity with execution intent
- descriptor validity and schema presence
- any new behavior added by the template change

If a template change alters generated behavior, update the generated tests in the same change.