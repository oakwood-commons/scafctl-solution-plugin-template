---
description: "Auth-handler template guidance for scafctl plugins: lifecycle, login flow semantics, token behavior, and test expectations."
applyTo: "scafctl/templates/internal/PKG_NAME/auth_handler*.go.tpl"
---

# scafctl Auth-Handler Template Guidance

Use this guidance when editing auth-handler Go templates in this solution repository.

## Template Scope

This repository generates auth-handler repositories from templates.

- Preserve placeholders such as `<% .provider_name %>`, `<% .display_name %>`, and `<% .pkg_name %>`.
- Keep generated tests, docs, and AI help aligned with runtime behavior.

## Handler Responsibilities

Generated auth-handler code should keep responsibilities separated.

- `GetAuthHandlers` describes the handler contract: name, display name, flows, and capabilities.
- `ConfigureAuthHandler` stores host-side configuration for later use.
- `Login` performs the authentication flow and returns claims plus expiry metadata.
- `GetStatus` reports current auth state without forcing login.
- `GetToken` returns a valid token or a clear authentication error.
- `Logout`, `ListCachedTokens`, `PurgeExpiredTokens`, and `StopAuthHandler` should be safe and predictable.

## Auth Semantics

- Reject unknown handler names consistently across methods.
- Keep claims, expiry, login flow, and status behavior internally consistent.
- Do not claim capabilities or flows that the generated implementation does not support.
- Keep placeholder behavior realistic enough for generated examples and tests.

## Token and Status Rules

- `GetToken` should not silently invent authenticated state.
- `GetStatus` should reflect whether the handler can currently serve requests.
- Cached-token methods should behave coherently with the login/token model.

## Test Expectations

Generated auth-handler tests should cover at least:

- known handler vs unknown handler
- login behavior
- logout behavior
- status behavior
- unauthenticated token access
- cached-token and purge behavior
- any configuration-dependent or flow-specific behavior introduced by the template change