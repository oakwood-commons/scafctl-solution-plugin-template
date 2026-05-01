# Contributing to scafctl-solution-plugin-template

Thank you for your interest in contributing!

## Prerequisites

- [scafctl CLI](https://github.com/oakwood-commons/scafctl/releases) (>= 0.35.0)
- [Task](https://taskfile.dev/installation/) (go-task runner)
- Go 1.26+ (only needed for `task validate`)

## Development Workflow

1. Fork and clone the repository
2. Create a feature branch: `git checkout -b feat/my-change`
3. Make your changes
4. Run the CI pipeline locally: `task ci`
5. Commit with DCO sign-off: `git commit -s -S -m "feat: my change"`
6. Push and open a pull request

## Commit Conventions

All commits must:

- Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- Be GPG/SSH signed (`-S`)
- Include DCO sign-off (`-s` / `Signed-off-by:` line)

```bash
git commit -s -S -m "feat: add new template for X"
```

## Running Tests

```bash
task lint       # Lint the solution YAML
task test       # Run functional tests (CEL assertions)
task validate   # Render output and verify it compiles
task ci         # Full pipeline
```

## Solution Structure

- `solution.yaml` -- Solution specification (resolvers, workflow, testing)
- `templates/` -- Go template files (using `<%` / `%>` delimiters)

## Template Conventions

- Use `<%` and `%>` as template delimiters (avoids conflicts with `{{`/`}}` in generated YAML)
- File placeholders: `PLUGIN_NAME` and `PKG_NAME` in paths are replaced at render time
- Files ending in `.tpl` have the extension stripped in output

## Versioning

- Breaking template changes: major version bump
- New template files or features: minor version bump
- Bug fixes and typo corrections: patch version bump

## Support SLA

- Triage: 1-2 weeks
- Review: 2 weeks
- Security reports: 48 hours (see SECURITY.md)
