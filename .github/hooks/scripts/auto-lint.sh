#!/bin/sh
# Post-tool-use hook: auto-lint after solution YAML edits
input_json=$(cat)
[ -z "$input_json" ] && exit 0

tool_name=$(echo "$input_json" | grep -o '"toolName":"[^"]*"' | head -1 | cut -d'"' -f4)
case "$tool_name" in edit_file|create_file|insert_edit|replace_string) ;; *) exit 0 ;; esac

file_path=$(echo "$input_json" | grep -o '"filePath":"[^"]*"' | head -1 | cut -d'"' -f4)
[ -z "$file_path" ] && file_path=$(echo "$input_json" | grep -o '"path":"[^"]*"' | head -1 | cut -d'"' -f4)
[ -z "$file_path" ] && exit 0

case "$file_path" in *.yaml|*.yml) ;; *) exit 0 ;; esac
case "$file_path" in *scafctl/*|*solution.yaml|*actions.yaml|*tests.yaml) ;; *) exit 0 ;; esac

result=$(scafctl lint 2>&1)
if [ $? -ne 0 ]; then
  escaped=$(echo "$result" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')
  printf '{"continue":true,"systemMessage":"Auto-lint found issues after editing %s: %s Fix these before proceeding."}' "$file_path" "$escaped"
fi
exit 0
