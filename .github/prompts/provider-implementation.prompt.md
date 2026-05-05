---
description: "Implement or refine generated provider scaffolding while keeping descriptor, execution, WhatIf, and tests aligned."
---
# Provider Implementation

Use this prompt when editing provider scaffold files in this solution repository.

## Goal

Make provider-facing scaffold changes without breaking the generated provider contract.

## Workflow

1. Identify every generated surface affected by the change:
   - `provider.go.tpl`
   - `provider_test.go.tpl`
   - `README.md.tpl`
   - static `.github` guidance for generated repos
2. Define the intended generated behavior in one paragraph.
3. Update the provider template so `GetProviderDescriptor`, `ExecuteProvider`, and `DescribeWhatIf` stay aligned.
4. Update tests in the same change.
5. Update generated docs or AI guidance if the contract changed.

## Required Checks

- Capabilities match the generated implementation.
- Schema fields and examples match runtime expectations.
- Unknown provider handling is consistent.
- Nil, empty, and zero-value input behavior is deliberate.
- `DescribeWhatIf` remains side-effect free.
- Generated tests would catch a mismatch between descriptor, execution, and WhatIf behavior.

## Output

Summarize:
- what changed in generated behavior
- which template files were updated
- which tests were updated
- any remaining edge cases or follow-up work