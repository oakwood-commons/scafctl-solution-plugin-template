# Creates an auth-handler plugin.
$ErrorActionPreference = 'Stop'

scafctl run solution -f scafctl/solution.yaml `
    -r name=scafctl-plugin-myauth `
    -r module=github.com/myorg/scafctl-plugin-myauth `
    -r 'description=Custom authentication handler for internal registry' `
    -r plugin_type=auth-handler `
    -r create_repo=false
