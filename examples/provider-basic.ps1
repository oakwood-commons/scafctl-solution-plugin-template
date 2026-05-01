# Creates a minimal provider plugin with the default "from" capability.
$ErrorActionPreference = 'Stop'

scafctl run solution -f scafctl/solution.yaml `
    -r name=scafctl-plugin-echo `
    -r module=github.com/myorg/scafctl-plugin-echo `
    -r 'description=Echoes input values back as resolver output' `
    -r plugin_type=provider `
    -r capabilities=from `
    -r create_repo=false
