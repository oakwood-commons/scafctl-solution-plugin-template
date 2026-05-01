# Creates a provider plugin with all four capabilities.
$ErrorActionPreference = 'Stop'

scafctl run solution -f scafctl/solution.yaml `
    -r name=scafctl-plugin-allcaps `
    -r module=github.com/myorg/scafctl-plugin-allcaps `
    -r 'description=Provider with from, transform, action, and validation capabilities' `
    -r plugin_type=provider `
    -r capabilities=from,transform,action,validation `
    -r create_repo=false
