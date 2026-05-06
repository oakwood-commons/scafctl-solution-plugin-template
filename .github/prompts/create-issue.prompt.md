---
description: "File an issue as a local markdown file with verification and feasibility assessment. Optionally submit plugin template issues upstream."
agent: "issue-creator"
argument-hint: "Describe the problem (e.g., 'MCP lint tool returns false positive for valid CEL')"
---
Create an issue file in `./issues/` for a scafctl ecosystem problem. There are two types:

**Type 1 -- Plugin Template issues** (AI instructions, MCP tool guidance, scaffolding, docs):
Filed locally, then optionally submitted to `oakwood-commons/scafctl-solution-plugin-template`.

**Type 2 -- Tooling bugs** (scafctl CLI, engine, providers):
Filed locally only. User submits manually when ready.

1. **Verify** the claim first -- run commands or check code to confirm bugs are reproducible and features don't already exist. If the claim is wrong, tell the user instead of filing.
2. **Explore** the codebase for relevant files, patterns, and interfaces
3. **Assess** feasibility, scope (XS/S/M/L/XL), risks, and affected areas
4. **Wait** for user confirmation before creating anything
5. **Create** the issue as a markdown file in the `./issues/` directory with appropriate title and structured body
6. **Submit upstream** (Type 1 only, optional) -- if the user asks, use the github provider MCP tool to file it on `oakwood-commons/scafctl-solution-plugin-template`
