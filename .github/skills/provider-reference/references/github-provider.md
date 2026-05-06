# GitHub Provider

Full GitHub API via GraphQL (reads, issues, PRs, commits, branches, tags, repos,
review threads, branch protection) and REST (releases, CI check runs, workflow runs,
security settings). Uses the configured GitHub auth handler automatically.
Capabilities: `from`, `transform`, `action`.

## Read Operations

- `get_repo`, `get_file`, `get_branch`, `get_issue`, `get_pull_request`,
  `get_latest_release`, `get_head_oid`, `get_workflow_run`
- `list_issues`, `list_issue_comments`, `list_pull_requests`, `list_pr_comments`,
  `list_review_threads`, `list_branches`, `list_tags`, `list_releases`,
  `list_check_runs`

## Write Operations

- `create_issue`, `update_issue`, `create_issue_comment`
- `create_pull_request`, `update_pull_request`, `merge_pull_request`,
  `close_pull_request`
- `reply_to_review_thread`, `resolve_review_thread`
- `create_commit` (GPG-signed, multi-file, atomic)
- `create_branch`, `delete_branch`, `create_tag`, `delete_tag`
- `create_release`, `update_release`, `delete_release`
- `create_repo`

## Security/Admin

- `create_ruleset`, `enable_vulnerability_alerts`, `enable_automated_security_fixes`

## Examples

~~~yaml
# List open issues
resolve:
  with:
    - provider: github
      inputs:
        operation: list_issues
        owner: my-org
        repo: my-repo
        state: open
        # per_page: 30              # Max 100
        # labels: [bug, priority/high]

# Create an issue
actions:
  create-issue:
    provider: github
    inputs:
      operation: create_issue
      owner: my-org
      repo: my-repo
      title: "Bug: something is broken"
      body: "Steps to reproduce..."
      labels: [bug]
      assignees: [username]

# GPG-signed multi-file commit
actions:
  commit-files:
    provider: github
    inputs:
      operation: create_commit
      owner: my-org
      repo: my-repo
      branch: feature-branch
      message: "feat: add scaffolded files"
      expected_head_oid:
        rslvr: headOid
      additions:
        - path: src/main.go
          content: "package main\n"
        - path: README.md
          content: "# My Project\n"

# Branch protection via rulesets
actions:
  protect-main:
    provider: github
    inputs:
      operation: create_ruleset
      owner: my-org
      repo: my-repo
      ruleset_name: main branch protection
      target: branch
      enforcement: active
      include_refs: ["refs/heads/main"]
      required_status_checks_contexts: [test, lint]
      required_approving_review_count: 1
~~~

## Key Fields

- `operation` (required), `owner`, `repo` -- other fields depend on the operation
- Always call `get_provider_schema github` to verify field names
- Returns an object -- access via `expr: "_.ghResult.result"`
- Auth uses `scafctl auth login github` token automatically
- For GitHub Enterprise, set `api_base`