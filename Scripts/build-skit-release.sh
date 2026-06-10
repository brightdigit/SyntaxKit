#!/usr/bin/env bash
#
# Build a self-contained skit release bundle.
#
# Output: .build/skit-release/
#   skit                            ← the CLI binary
#   lib/
#     libSyntaxKit.dylib            ← release + strip -x
#     *.swiftmodule                 ← SyntaxKit + transitively re-exported modules
#     _SwiftSyntaxCShims-include/   ← C-shims headers (module map + .h files)
#     swift-version.txt             ← toolchain stamp for startup check
#
# Once produced, the bundle is portable: copy the whole .build/skit-release/
# directory anywhere, and `./skit-release/skit <input>` Just Works — no
# flags, no env vars, no SyntaxKit checkout required.

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS-only. Linux uses a parallel flow (build, then strip the" >&2
  echo "Mach-O install_name step)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/.build/skit-release"

cd "$REPO_ROOT"

# Build the SyntaxKit library product as a dynamic libSyntaxKit.dylib. Package.swift
# reads SYNTAXKIT_DYNAMIC_LIB and flips the library product to type: .dynamic, so
# we never mutate the canonical manifest.
echo "==> Building with SYNTAXKIT_DYNAMIC_LIB=1 (dynamic libSyntaxKit)"
export SYNTAXKIT_DYNAMIC_LIB=1

echo "==> swift build -c release --product skit"
swift build -c release --product skit

# `skit` doesn't depend on SyntaxKit (it spawns swift on user input that
# imports SyntaxKit at runtime). Build the library product explicitly so the
# .dynamic flip above produces libSyntaxKit.dylib + swiftmodule.
echo "==> swift build -c release --product SyntaxKit"
swift build -c release --product SyntaxKit

BUILD_DIR="$(ls -d .build/*-apple-macosx*/release 2>/dev/null | head -1)"
if [[ -z "$BUILD_DIR" ]]; then
  echo "Could not locate release build dir under .build/<triple>/release" >&2
  exit 1
fi

echo "==> Staging $OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/lib"

cp "$BUILD_DIR/skit" "$OUTPUT_DIR/skit"
cp "$BUILD_DIR/libSyntaxKit.dylib" "$OUTPUT_DIR/lib/"
strip -x "$OUTPUT_DIR/lib/libSyntaxKit.dylib"
cp -r "$BUILD_DIR/Modules/." "$OUTPUT_DIR/lib/"
cp -r "$REPO_ROOT/.build/checkouts/swift-syntax/Sources/_SwiftSyntaxCShims/include" \
      "$OUTPUT_DIR/lib/_SwiftSyntaxCShims-include"

# Ensure the dylib's install_name uses @rpath so it's portable.
install_name_tool -id "@rpath/libSyntaxKit.dylib" "$OUTPUT_DIR/lib/libSyntaxKit.dylib" 2>/dev/null || true

# Stamp the bundle with the build toolchain. `skit` compares this against the
# user's `swift --version` at startup and refuses to spawn `swift` if the
# swiftmodule wouldn't load. Issue #157 will replace the refusal with an
# auto-rebuild fallback.
swift --version > "$OUTPUT_DIR/lib/swift-version.txt"

BINARY_SIZE=$(ls -lh "$OUTPUT_DIR/skit" | awk '{print $5}')
DYLIB_SIZE=$(ls -lh "$OUTPUT_DIR/lib/libSyntaxKit.dylib" | awk '{print $5}')
TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" | awk '{print $1}')

echo
echo "==> Release bundle ready:"
echo "  Binary:  $BINARY_SIZE"
echo "  Dylib:   $DYLIB_SIZE"
echo "  Total:   $TOTAL_SIZE"
echo
echo "==> Try it:"
echo "  $OUTPUT_DIR/skit run <some-input.swift>"
