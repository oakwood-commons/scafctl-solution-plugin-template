---
applyTo: "**"
---

# scafctl Issue Reporting

When the AI encounters persistent problems helping the user with scafctl solution
development, it should consider filing an issue against the plugin template solution
repository at `oakwood-commons/scafctl-solution-plugin-template`. This applies to issues with:

- scafctl MCP tools returning unexpected errors or inconsistent results
- AI instruction files producing incorrect or misleading guidance
- Missing or incorrect documentation in scaffolded files
- Provider behavior that contradicts documented schemas
- Patterns that require non-idiomatic workarounds

This does NOT apply to:

- General coding questions unrelated to scafctl solutions
- Issues with the user's own solution logic or business rules
- Problems in third-party tools, CLIs, or services
- Questions about languages, frameworks, or libraries outside scafctl

## How to File

**Always use the `issue-creator` agent** -- do NOT create issue files directly.
The agent enforces a structured workflow:

1. **Understand** the problem
2. **Research & verify** the claim (reproduce bugs, confirm features don't exist)
3. **Explore** the codebase for technical context
4. **Assess** feasibility, scope, and give a recommendation on whether to file
5. **Ask the user for confirmation** before creating any file
6. **Create the issue file** in `./issues/`
7. **Optionally submit upstream** (Type 1 ai-provider issues only)

## Before Filing

Follow these steps before considering an issue:

1. **Try multiple approaches** -- attempt at least 2-3 different strategies to solve
   the problem. Do not file after a single failure.
2. **Check for updates** -- verify the user is on the latest scafctl version.
   The issue may already be fixed. Use `scafctl version` to check current version
   and compare against the latest release on GitHub.
3. **Ask the user** -- always get explicit permission before filing or commenting
   on an issue. Explain what you found, what you tried, and why you think it
   warrants an issue.
