# Creates a provider plugin AND a GitHub repository with branch protection.
# Requires: gh CLI authenticated, scafctl with GitHub auth configured.
$ErrorActionPreference = 'Stop'

scafctl run solution -f solution.yaml `
    -r name=scafctl-plugin-myecho `
    -r module=github.com/myorg/scafctl-plugin-myecho `
    -r 'description=Echoes input values back as resolver output' `
    -r plugin_type=provider `
    -r capabilities=from,transform `
    -r create_repo=true `
    -r repo_visibility=public
