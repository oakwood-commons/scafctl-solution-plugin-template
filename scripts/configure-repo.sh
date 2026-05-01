#!/usr/bin/env bash
set -euo pipefail

# Configures the GitHub repository to match scafctl conventions.
# Prerequisites: gh CLI authenticated with admin permissions.

OWNER="oakwood-commons"
REPO="scafctl-solution-plugin-template"
FULL="${OWNER}/${REPO}"

echo "Configuring ${FULL}..."

# ── Repo Settings ─────────────────────────────────────────────────────────────
echo "  Setting merge strategy and branch cleanup..."
gh repo edit "$FULL" \
  --delete-branch-on-merge \
  --enable-squash-merge \
  --disable-merge-commit \
  --disable-rebase-merge \
  --enable-auto-merge \
  --enable-issues \
  --enable-projects=false \
  --enable-wiki=false

# ── Web commit sign-off requirement ──────────────────────────────────────────
echo "  Requiring web commit sign-off..."
gh api -X PATCH "repos/${FULL}" \
  -f web_commit_signoff_required=true

# ── Branch Ruleset ────────────────────────────────────────────────────────────
echo "  Creating branch ruleset..."
gh api -X POST "repos/${FULL}/rulesets" \
  --input - <<'EOF'
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
        "require_last_push_approval": true
      }
    },
    { "type": "required_linear_history" },
    { "type": "required_signatures" },
    { "type": "non_fast_forward" }
  ]
}
EOF

# ── Tag Ruleset ───────────────────────────────────────────────────────────────
echo "  Creating tag ruleset..."
gh api -X POST "repos/${FULL}/rulesets" \
  --input - <<'EOF'
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
EOF

# ── Security Features ─────────────────────────────────────────────────────────
echo "  Enabling vulnerability alerts..."
gh api -X PUT "repos/${FULL}/vulnerability-alerts" 2>/dev/null || true

echo "  Enabling automated security fixes..."
gh api -X PUT "repos/${FULL}/automated-security-fixes" 2>/dev/null || true

# ── Copilot Autofix / Code Scanning ──────────────────────────────────────────
echo "  Enabling code scanning (Copilot Autofix)..."
gh api -X PATCH "repos/${FULL}" \
  --input - <<'EOF' 2>/dev/null || echo "  (code scanning may require manual enablement)"
{
  "security_and_analysis": {
    "advanced_security": { "status": "enabled" },
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}
EOF

# ── Labels ────────────────────────────────────────────────────────────────────
echo "  Creating labels..."
for label in "bug" "enhancement" "documentation" "security" "breaking-change" "template"; do
  gh label create "$label" --repo "$FULL" --force 2>/dev/null || true
done

echo ""
echo "Repository configured successfully."
