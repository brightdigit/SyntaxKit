#!/usr/bin/env bash
#
# Build a self-contained skit bundle.
#
#   ./Scripts/build-skit.sh           # release bundle  → .build/skit-release/
#   ./Scripts/build-skit.sh --debug   # debug bundle    → .build/skit-debug/
#
# Output: .build/skit-${CONFIG}/
#   skit                            ← the CLI binary
#   lib/
#     libSyntaxKit.dylib            ← release: stripped; debug: as-built
#     *.swiftmodule                 ← SyntaxKit + transitively re-exported modules
#     _SwiftSyntaxCShims-include/   ← C-shims headers (module map + .h files)
#     swift-version.txt             ← toolchain stamp for startup check
#
# Once produced, the bundle is portable: copy the whole directory anywhere,
# and `./skit-${CONFIG}/skit <input>` Just Works — no flags, no env vars, no
# SyntaxKit checkout required. The release variant runs a 5–15 minute
# optimized SwiftSyntax compile; the debug variant skips that and finishes
# in ~10 seconds (use it for local iteration).

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS-only. Linux uses a parallel flow (build, then strip the" >&2
  echo "Mach-O install_name step)." >&2
  exit 1
fi

CONFIG="release"
SWIFT_CONFIG_FLAGS=()
STRIP_DYLIB=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug)
      CONFIG="debug"
      SWIFT_CONFIG_FLAGS=()
      STRIP_DYLIB=0
      ;;
    --release)
      CONFIG="release"
      SWIFT_CONFIG_FLAGS=(-c release)
      STRIP_DYLIB=1
      ;;
    -h | --help)
      sed -n '2,18p' "$0"
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
  shift
done

# Default config is release; SWIFT_CONFIG_FLAGS was left empty so set it here.
if [[ "$CONFIG" == "release" && ${#SWIFT_CONFIG_FLAGS[@]} -eq 0 ]]; then
  SWIFT_CONFIG_FLAGS=(-c release)
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/.build/skit-${CONFIG}"

cd "$REPO_ROOT"

# Build the SyntaxKit library product as a dynamic libSyntaxKit.dylib. Package.swift
# reads SYNTAXKIT_DYNAMIC_LIB and flips the library product to type: .dynamic, so
# we never mutate the canonical manifest.
echo "==> Building with SYNTAXKIT_DYNAMIC_LIB=1 (dynamic libSyntaxKit)"
export SYNTAXKIT_DYNAMIC_LIB=1

echo "==> swift build ${SWIFT_CONFIG_FLAGS[*]} --product skit"
swift build "${SWIFT_CONFIG_FLAGS[@]}" --product skit

# `skit` doesn't depend on SyntaxKit (it spawns swift on user input that
# imports SyntaxKit at runtime). Build the library product explicitly so the
# .dynamic flip above produces libSyntaxKit.dylib + swiftmodule.
echo "==> swift build ${SWIFT_CONFIG_FLAGS[*]} --product SyntaxKit"
swift build "${SWIFT_CONFIG_FLAGS[@]}" --product SyntaxKit

BUILD_DIR="$(ls -d .build/*-apple-macosx*/"${CONFIG}" 2>/dev/null | head -1)"
if [[ -z "$BUILD_DIR" ]]; then
  echo "Could not locate ${CONFIG} build dir under .build/<triple>/${CONFIG}" >&2
  exit 1
fi

echo "==> Staging $OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/lib"

cp "$BUILD_DIR/skit" "$OUTPUT_DIR/skit"
cp "$BUILD_DIR/libSyntaxKit.dylib" "$OUTPUT_DIR/lib/"
if [[ "$STRIP_DYLIB" == "1" ]]; then
  strip -x "$OUTPUT_DIR/lib/libSyntaxKit.dylib"
fi
cp -r "$BUILD_DIR/Modules/." "$OUTPUT_DIR/lib/"
cp -r "$REPO_ROOT/.build/checkouts/swift-syntax/Sources/_SwiftSyntaxCShims/include" \
      "$OUTPUT_DIR/lib/_SwiftSyntaxCShims-include"

# Ensure the dylib's install_name uses @rpath so the bundle is portable.
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
echo "==> ${CONFIG} bundle ready:"
echo "  Binary:  $BINARY_SIZE"
echo "  Dylib:   $DYLIB_SIZE"
echo "  Total:   $TOTAL_SIZE"
echo
echo "==> Try it:"
echo "  $OUTPUT_DIR/skit run <some-input.swift>"
