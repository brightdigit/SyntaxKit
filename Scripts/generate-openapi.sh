#!/bin/bash

# Regenerates the ClaudeKit client from the Anthropic OpenAPI spec.
# swift-openapi-generator is managed by mise (see mise.toml); the generated
# code is committed under Sources/ClaudeKit/Generated.
#
# Sources/ClaudeKit/openapi.json is the unofficial Anthropic OpenAPI spec
# (hosted_spec.json, retrieved 2026-06-11) from
# https://github.com/laszukdawid/anthropic-openapi-spec — to refresh it:
#   curl -o Sources/ClaudeKit/openapi.json \
#     https://raw.githubusercontent.com/laszukdawid/anthropic-openapi-spec/main/hosted_spec.json

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

# Generated files opt out of swift-format, Periphery, and the license header
# via the additionalFileComments in openapi-generator-config.yaml (header.sh
# skips files carrying swift-format-ignore-file); SwiftLint excludes the
# Generated directory in .swiftlint.yml.
