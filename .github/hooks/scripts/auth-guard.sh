#!/bin/sh
# Pre-tool-use hook: block non-scafctl auth commands
input_json=$(cat)
[ -z "$input_json" ] && exit 0

tool_name=$(echo "$input_json" | grep -o '"toolName":"[^"]*"' | head -1 | cut -d'"' -f4)
case "$tool_name" in run_in_terminal|run_command|terminal) ;; *) exit 0 ;; esac

command=$(echo "$input_json" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4)
[ -z "$command" ] && exit 0

for pattern in "az login" "az account" "gcloud auth login" "gcloud auth application-default" "aws configure" "aws sso login"; do
  case "$command" in
    *"$pattern"*)
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Use scafctl auth login <handler> instead of %s. scafctl manages authentication."}}' "$pattern"
      exit 0 ;;
  esac
done
exit 0
