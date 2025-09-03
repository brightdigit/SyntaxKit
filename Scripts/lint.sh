#!/bin/bash

# Remove set -e to prevent immediate exit on errors
# set -e  # Exit on any error

ERRORS=0

run_command() {
		if [ "$LINT_MODE" = "STRICT" ]; then
				"$@" || ERRORS=$((ERRORS + 1))
		else
				"$@" || ERRORS=$((ERRORS + 1))
		fi
}

if [ "$LINT_MODE" = "INSTALL" ]; then
	exit
fi

echo "LintMode: $LINT_MODE"

# More portable way to get script directory
if [ -z "$SRCROOT" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    PACKAGE_DIR="${SCRIPT_DIR}/.."
else
    PACKAGE_DIR="${SRCROOT}"
fi

# Detect OS and set paths accordingly
if [ "$(uname)" = "Darwin" ]; then
    DEFAULT_MINT_PATH="/opt/homebrew/bin/mint"
elif [ "$(uname)" = "Linux" ] && [ -n "$GITHUB_ACTIONS" ]; then
    DEFAULT_MINT_PATH="$GITHUB_WORKSPACE/Mint/.mint/bin/mint"
elif [ "$(uname)" = "Linux" ]; then
    DEFAULT_MINT_PATH="/usr/local/bin/mint"
else
    echo "Unsupported operating system"
    exit 1
fi

# Use environment MINT_CMD if set, otherwise use default path
MINT_CMD=${MINT_CMD:-$DEFAULT_MINT_PATH}

export MINT_PATH="$PACKAGE_DIR/.mint"
MINT_ARGS="-n -m $PACKAGE_DIR/Mintfile --silent"
MINT_RUN="$MINT_CMD run $MINT_ARGS"

if [ "$LINT_MODE" = "NONE" ]; then
	exit
elif [ "$LINT_MODE" = "STRICT" ]; then
	SWIFTFORMAT_OPTIONS="--strict --configuration .swift-format"
	SWIFTLINT_OPTIONS="--strict"
	STRINGSLINT_OPTIONS="--config .strict.stringslint.yml"
else 
	SWIFTFORMAT_OPTIONS="--configuration .swift-format"
	SWIFTLINT_OPTIONS=""
	STRINGSLINT_OPTIONS="--config .stringslint.yml"
fi

pushd $PACKAGE_DIR
run_command $MINT_CMD bootstrap -m Mintfile

if [ -z "$CI" ]; then
	run_command $MINT_RUN swift-format format $SWIFTFORMAT_OPTIONS  --recursive --parallel --in-place Sources Tests
	run_command $MINT_RUN swiftlint --fix
fi

if [ -z "$FORMAT_ONLY" ]; then
    run_command $MINT_RUN swift-format lint --configuration .swift-format --recursive --parallel $SWIFTFORMAT_OPTIONS Sources Tests
    run_command $MINT_RUN swiftlint lint $SWIFTLINT_OPTIONS
fi

$PACKAGE_DIR/Scripts/header.sh -d  $PACKAGE_DIR/Sources -c "Leo Dion" -o "BrightDigit" -p "SyntaxKit"

run_command $MINT_RUN swiftlint lint $SWIFTLINT_OPTIONS
run_command $MINT_RUN swift-format lint --recursive --parallel $SWIFTFORMAT_OPTIONS Sources Tests

if [ -z "$CI" ]; then
    run_command $MINT_RUN periphery scan $PERIPHERY_OPTIONS --disable-update-check
fi

# Documentation quality checks
if [ -z "$SKIP_DOCS" ]; then
	echo -e "\n🔍 Running comprehensive documentation quality checks..."
	
	# DocC generation with warnings as errors using Swift package plugin
	echo "Generating DocC documentation using Swift package plugin..."
	docc_output=$(mktemp)
	if ! swift package generate-documentation --warnings-as-errors 2>"$docc_output"; then
		echo "❌ DocC generation failed due to warnings or errors"
		echo "🔍 Error details:"
		while IFS= read -r line; do
			echo "   $line"
		done < "$docc_output"
		echo ""
		echo "💡 Common fixes:"
		echo "   • Add missing documentation comments (///) to public APIs"
		echo "   • Fix broken symbol references in documentation"
		echo "   • Resolve conflicting or ambiguous documentation links"
		echo "   • Check for invalid markdown syntax in .docc files"
		rm "$docc_output"
		ERRORS=$((ERRORS + 1))
	else
		echo "✅ DocC generation successful"
		rm "$docc_output"
	fi
	
	# Full documentation validation suite
	echo "Running documentation validation suite..."
	if ! $PACKAGE_DIR/Scripts/validate-docs.sh; then
		ERRORS=$((ERRORS + 1))
		echo ""
		echo -e "💡 \033[1;33mDocumentation Quality Help:\033[0m"
		echo "   Run individual checks for faster debugging:"
		echo "   • swift package generate-documentation  # Check for DocC warnings"
		echo "   • ./Scripts/api-coverage.sh --threshold 90  # Check API coverage"
		echo "   • ./Scripts/validate-docs.sh  # Full validation with detailed output"
		echo ""
		echo "   Skip documentation checks temporarily:"
		echo "   • SKIP_DOCS=1 ./Scripts/lint.sh"
	fi
fi

popd

# Return error count at the end instead of exiting immediately
if [ $ERRORS -gt 0 ]; then
    echo "Lint script completed with $ERRORS error(s)"
    exit $ERRORS
else
    echo "Lint script completed successfully"
    exit 0
fi
