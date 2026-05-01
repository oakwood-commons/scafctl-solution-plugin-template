#!/usr/bin/env bash
set -euo pipefail

# Renders the solution with test inputs, then validates the output compiles.
# Supports both provider and auth-handler plugin types.

PLUGIN_TYPE="${VALIDATE_PLUGIN_TYPE:-provider}"

OUTPUT_DIR=$(mktemp -d)
AUTH_DIR=""
cleanup() {
  rm -rf "$OUTPUT_DIR"
  if [ -n "$AUTH_DIR" ]; then
    rm -rf "$AUTH_DIR"
  fi
}
trap cleanup EXIT

NAME="scafctl-plugin-validate-${PLUGIN_TYPE}"
MODULE="github.com/test/${NAME}"

echo "=== Validating ${PLUGIN_TYPE} plugin output ==="
echo "  Output dir: ${OUTPUT_DIR}"

ARGS=(
  -r "name=${NAME}"
  -r "module=${MODULE}"
  -r "description=Validation test ${PLUGIN_TYPE} plugin"
  -r "plugin_type=${PLUGIN_TYPE}"
  -r "create_repo=false"
  -r "repo_visibility=public"
)

if [ "$PLUGIN_TYPE" = "provider" ]; then
  ARGS+=(-r "capabilities=from,transform")
fi

scafctl run solution -f scafctl/solution.yaml "${ARGS[@]}" --output-dir "$OUTPUT_DIR"

cd "$OUTPUT_DIR/${NAME}"

echo ""
echo "  Running go mod tidy..."
go mod tidy

echo "  Running go build..."
go build ./...

echo "  Running go vet..."
go vet ./...

echo "  Running go test..."
go test ./...

echo ""
echo "=== ${PLUGIN_TYPE} output compiles and tests pass ==="

# If no specific type was requested, also validate the other variant
if [ -z "${VALIDATE_PLUGIN_TYPE:-}" ]; then
  echo ""
  echo "=== Validating auth-handler plugin output ==="

  AUTH_DIR=$(mktemp -d)

  AUTH_NAME="scafctl-plugin-validate-auth"
  AUTH_MODULE="github.com/test/${AUTH_NAME}"

  scafctl run solution -f "${OLDPWD}/scafctl/solution.yaml" \
    -r "name=${AUTH_NAME}" \
    -r "module=${AUTH_MODULE}" \
    -r "description=Validation test auth-handler plugin" \
    -r "plugin_type=auth-handler" \
    -r "create_repo=false" \
    -r "repo_visibility=public" \
    --output-dir "$AUTH_DIR"

  cd "$AUTH_DIR/${AUTH_NAME}"

  echo "  Running go mod tidy..."
  go mod tidy

  echo "  Running go build..."
  go build ./...

  echo "  Running go vet..."
  go vet ./...

  echo "  Running go test..."
  go test ./...

  echo ""
  echo "=== auth-handler output compiles and tests pass ==="
fi
