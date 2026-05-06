---
description: "Review auth-handler scaffold changes for scafctl login semantics, token behavior, status reporting, and tests."
---
# Auth-Handler Scaffold Review

Review the current scaffold changes specifically for scafctl auth-handler behavior.

## Phase 1: Identify auth-handler-facing changes

1. Inspect changed files under `scafctl/templates/`, `scafctl/static/.github/`, and `scafctl/solution.yaml`.
2. Focus on changes that affect generated auth-handler repositories, especially:
   - `auth_handler.go.tpl`
   - `auth_handler_test.go.tpl`
   - `README.md.tpl`
   - generated `.github` instructions and prompts

## Phase 2: Check auth contract correctness

- Does `GetAuthHandlers` accurately describe flows and capabilities?
- Do handler name, display name, flows, capabilities, and examples stay coherent?
- Do docs and tests reflect the generated authentication behavior?

## Phase 3: Check lifecycle behavior

- Are unknown handler names rejected consistently?
- Does `Login` return coherent claims and expiry information?
- Does `GetStatus` reflect authentication state rather than mutating it?
- Does `GetToken` return a valid token or a clear auth error?
- Are logout and token-cache methods consistent with the rest of the model?

## Phase 4: Check generated tests

- Do generated tests cover login, status, token, logout, and unknown handler behavior?
- If behavior changed, were the generated tests updated in the same change?
- Are solution-level functional tests still proving the right AI files are emitted?

## Output format

Use severity levels: HIGH, MEDIUM, LOW.

For each finding include:
- file
- severity
- issue
- recommended fix

If no findings are present, say that explicitly and mention any residual risk.