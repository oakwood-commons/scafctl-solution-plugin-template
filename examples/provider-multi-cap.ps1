# Creates a provider plugin with all supported capabilities.
$ErrorActionPreference = 'Stop'

scafctl run solution -f scafctl/solution.yaml `
    -r name=scafctl-plugin-allcaps `
    -r module=github.com/myorg/scafctl-plugin-allcaps `
    -r 'description=Provider exercising all supported capabilities' `
    -r plugin_type=provider `
    -r capabilities=from,transform,action,validation,state,kubeconfig `
    -r create_repo=false
