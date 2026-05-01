#!/usr/bin/env bash
# Creates a minimal provider plugin with the default "from" capability.
set -euo pipefail

scafctl run solution -f solution.yaml \
  -r name=scafctl-plugin-echo \
  -r module=github.com/myorg/scafctl-plugin-echo \
  -r description="Echoes input values back as resolver output" \
  -r plugin_type=provider \
  -r capabilities=from \
  -r create_repo=false
