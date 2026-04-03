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
if [ -z "$CI" ]; then
    mise install
fi
eval "$(mise env)"

if [ -z "$CI" ]; then
	run_command swift-format format $SWIFTFORMAT_OPTIONS  --recursive --parallel --in-place Sources Tests
	run_command swiftlint --fix
fi

if [ -z "$FORMAT_ONLY" ]; then
    run_command swift-format lint --configuration .swift-format --recursive --parallel $SWIFTFORMAT_OPTIONS Sources Tests
    run_command swiftlint lint $SWIFTLINT_OPTIONS
fi

$PACKAGE_DIR/Scripts/header.sh -d  $PACKAGE_DIR/Sources -c "Leo Dion" -o "BrightDigit" -p "SyntaxKit"

run_command swiftlint lint $SWIFTLINT_OPTIONS
run_command swift-format lint --recursive --parallel $SWIFTFORMAT_OPTIONS Sources Tests

if [ -z "$CI" ]; then
    run_command periphery scan $PERIPHERY_OPTIONS --disable-update-check
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
