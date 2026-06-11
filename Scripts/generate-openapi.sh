#!/bin/bash

# Regenerates the ClaudeKit client from the Anthropic OpenAPI spec.
# swift-openapi-generator is managed by mise (see mise.toml); the generated
# code is committed under Sources/ClaudeKit/Generated.

set -e

# More portable way to get script directory
if [ -z "$SRCROOT" ]; then
	SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
	PACKAGE_DIR="${SCRIPT_DIR}/.."
else
	PACKAGE_DIR="${SRCROOT}"
fi

# Ensure mise-managed tools are on PATH outside CI (CI uses jdx/mise-action)
if command -v mise >/dev/null 2>&1 && [ -z "$CI" ]; then
	eval "$(mise -C "$PACKAGE_DIR" env -s bash)"
fi

cd "$PACKAGE_DIR"

mkdir -p Sources/ClaudeKit/Generated

swift-openapi-generator generate \
	--config Sources/ClaudeKit/openapi-generator-config.yaml \
	--output-directory Sources/ClaudeKit/Generated \
	Sources/ClaudeKit/openapi.json

# Match the formatting and license headers lint.sh applies to Sources, so the
# committed generated code passes CI's swift-format lint and stays stable
# across regenerations.
swift-format format --configuration .swift-format --recursive --parallel --in-place Sources/ClaudeKit/Generated
"$PACKAGE_DIR/Scripts/header.sh" -d "$PACKAGE_DIR/Sources/ClaudeKit/Generated" -c "Leo Dion" -o "BrightDigit" -p "SyntaxKit"
