---
description: "Review provider-related scaffold changes for scafctl plugin semantics, generated API contracts, and test coverage."
---
# Provider Scaffold Review

Review the current scaffold changes specifically for scafctl provider behavior.

## Phase 1: Identify provider-facing changes

1. Inspect changed files under `scafctl/templates/`, `scafctl/static/.github/`, and `scafctl/solution.yaml`.
2. Focus on changes that affect generated provider repositories, especially:
   - `provider.go.tpl`
   - `provider_test.go.tpl`
   - `README.md.tpl`
   - generated `.github` instructions and prompts
3. Summarize the generated behavior change in one paragraph before reviewing details.

## Phase 2: Check provider contract correctness

- Does `GetProviderDescriptor` describe the same contract that generated code implements?
- Do capability constants match the supported behavior?
- Do schema fields, required fields, and examples match the generated implementation?
- Do README examples match the schema and expected provider output?

## Phase 3: Check provider lifecycle behavior

- Is `cmd/.../main.go` still a thin entry point?
- Does generated `ExecuteProvider` reject unknown providers consistently?
- Does generated `DescribeWhatIf` remain side-effect free and aligned with execution intent?
- Are `ConfigureProvider`, `ExecuteProviderStream`, `ExtractDependencies`, and `StopProvider` still reasonable defaults?

## Phase 4: Check generated tests

- Do generated tests cover happy path and unknown provider behavior?
- Do generated tests cover nil, empty, or zero-value inputs where relevant?
- If behavior changed, were the generated tests updated in the same change?
- Are solution-level functional tests in `scafctl/solution.yaml` still proving the right files are emitted?

## Output format

Use severity levels: HIGH, MEDIUM, LOW.

For each finding include:
- file
- severity
- issue
- recommended fix

If no findings are present, say that explicitly and mention any residual risk.