#!/usr/bin/env bash
# Creates an auth-handler plugin.
set -euo pipefail

scafctl run solution -f solution.yaml \
  -r name=scafctl-plugin-myauth \
  -r module=github.com/myorg/scafctl-plugin-myauth \
  -r description="Custom authentication handler for internal registry" \
  -r plugin_type=auth-handler \
  -r create_repo=false
