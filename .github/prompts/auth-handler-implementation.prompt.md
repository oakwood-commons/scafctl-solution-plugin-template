---
description: "Implement or refine generated auth-handler scaffolding while keeping handler metadata, login, token, status, docs, and tests aligned."
---
# Auth-Handler Implementation

Use this prompt when editing auth-handler scaffold files in this solution repository.

## Goal

Make auth-handler-facing scaffold changes without breaking the generated authentication contract.

## Workflow

1. Identify every generated surface affected by the change:
   - `auth_handler.go.tpl`
   - `auth_handler_test.go.tpl`
   - `README.md.tpl`
   - static `.github` guidance for generated repos
2. Define the intended generated authentication behavior in one paragraph.
3. Update the auth-handler template so `GetAuthHandlers`, `Login`, `GetStatus`, and `GetToken` stay aligned.
4. Update tests in the same change.
5. Update generated docs or AI guidance if the contract changed.

## Required Checks

- Flows and capabilities match the generated implementation.
- Unknown handler handling is consistent.
- Claims, expiry, token behavior, and status behavior are coherent.
- Unauthenticated and error paths are deliberate.
- Generated tests would catch drift between metadata, login, status, and token behavior.

## Output

Summarize:
- what changed in generated behavior
- which template files were updated
- which tests were updated
- any remaining edge cases or follow-up work