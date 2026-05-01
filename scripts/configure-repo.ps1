#Requires -Version 7.0
<#
.SYNOPSIS
    Configures the GitHub repository to match scafctl conventions.
.DESCRIPTION
    Requires gh CLI authenticated with admin permissions.
#>
$ErrorActionPreference = 'Stop'

$Owner = 'oakwood-commons'
$Repo = 'scafctl-solution-plugin-template'
$Full = "$Owner/$Repo"

Write-Host "Configuring $Full..."

# ── Repo Settings ─────────────────────────────────────────────────────────────
Write-Host '  Setting merge strategy and branch cleanup...'
& gh repo edit $Full `
    --delete-branch-on-merge `
    --enable-squash-merge `
    --enable-auto-merge `
    --enable-issues
if ($LASTEXITCODE -ne 0) { throw "gh repo edit failed" }

# Disable merge commit and rebase merge (no --disable flags in gh CLI)
Write-Host '  Disabling merge commit and rebase merge...'
& gh api -X PATCH "repos/$Full" `
    -f allow_merge_commit=false `
    -f allow_rebase_merge=false `
    -f has_projects=false `
    -f has_wiki=false
if ($LASTEXITCODE -ne 0) { throw "Failed to disable merge methods" }

# ── Web commit sign-off requirement ──────────────────────────────────────────
Write-Host '  Requiring web commit sign-off...'
& gh api -X PATCH "repos/$Full" -f web_commit_signoff_required=true
if ($LASTEXITCODE -ne 0) { throw "Failed to set web commit sign-off" }

# ── Branch Ruleset ────────────────────────────────────────────────────────────
Write-Host '  Creating branch ruleset...'
$branchRuleset = @'
{
  "name": "main branch protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/heads/main"], "exclude": [] }
  },
  "rules": [
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [
          { "context": "lint-and-test" },
          { "context": "validate-output (provider)" },
          { "context": "validate-output (auth-handler)" }
        ]
      }
    },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": true,
        "required_review_thread_resolution": false
      }
    },
    { "type": "required_linear_history" },
    { "type": "required_signatures" },
    { "type": "non_fast_forward" }
  ]
}
'@
$branchRuleset | & gh api -X POST "repos/$Full/rulesets" --input -
if ($LASTEXITCODE -ne 0) { throw "Failed to create branch ruleset" }

# ── Tag Ruleset ───────────────────────────────────────────────────────────────
Write-Host '  Creating tag ruleset...'
$tagRuleset = @'
{
  "name": "version tag protection",
  "target": "tag",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/tags/v*"], "exclude": [] }
  },
  "rules": [
    { "type": "non_fast_forward" }
  ]
}
'@
$tagRuleset | & gh api -X POST "repos/$Full/rulesets" --input -
if ($LASTEXITCODE -ne 0) { throw "Failed to create tag ruleset" }

# ── Security Features ─────────────────────────────────────────────────────────
Write-Host '  Enabling vulnerability alerts...'
& gh api -X PUT "repos/$Full/vulnerability-alerts" 2>$null
Write-Host '  Enabling automated security fixes...'
& gh api -X PUT "repos/$Full/automated-security-fixes" 2>$null

# ── Copilot Autofix / Code Scanning ──────────────────────────────────────────
Write-Host '  Enabling code scanning (Copilot Autofix)...'
$securityConfig = @'
{
  "security_and_analysis": {
    "advanced_security": { "status": "enabled" },
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}
'@
$securityConfig | & gh api -X PATCH "repos/$Full" --input - 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host '  (code scanning may require manual enablement)'
}

# ── Labels ────────────────────────────────────────────────────────────────────
Write-Host '  Creating labels...'
$labels = @('bug', 'enhancement', 'documentation', 'security', 'breaking-change', 'template')
foreach ($label in $labels) {
    & gh label create $label --repo $Full --force 2>$null
}

Write-Host ''
Write-Host 'Repository configured successfully.'
