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

- Keep `Name`, `DisplayName`, `Description`, `Capabilities`, `Schema`, and `OutputSchemas` internally consistent.
- Every declared capability must have a corresponding entry in `OutputSchemas`.
- Do not claim capabilities that the generated implementation does not support.
- A descriptor without `OutputSchemas` will fail host registration. The host validates descriptors before making providers available.
- Keep schema examples and required fields synchronized with the implementation and README snippets.
- Prefer clear input names and stable output shapes.

## OutputSchemas Contract

Generated descriptors must include `OutputSchemas` for every declared capability.

- The template iterates `.capability_consts` to produce both `Capabilities` and `OutputSchemas` entries.
- Missing `OutputSchemas` causes the host to reject the provider. The user sees `provider not found` because registration fails silently.
- Generated tests must assert that `OutputSchemas` is non-nil and covers every capability.
- When adding a new capability to the template, add the corresponding `OutputSchemas` entry in the same change.

## Provider Name vs Binary Name

Generated guidance should keep provider identity and executable naming separate.

- The provider identity comes from the published plugin or catalog name and the provider name returned over RPC, not from the exact binary filename.
- `GetProviders` should return the same provider name users reference in their solutions.
- `GetProviderDescriptor("name")` should describe that same provider name.
- The executable only needs to be runnable. On Windows that means it must end in `.exe`.
- Prefer names like `scafctl-plugin-<provider>` or `scafctl-plugin-<provider>.exe`, but treat that as convention, not a resolution rule.
- Do not teach users that the filename alone controls whether `provider:<name>` resolves.

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
- descriptor validity, schema presence, and `OutputSchemas` coverage for all capabilities
- any new behavior added by the template change

If a template change alters generated behavior, update the generated tests in the same change.