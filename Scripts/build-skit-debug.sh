#!/usr/bin/env bash
#
# Build a self-contained skit DEBUG bundle for fast local iteration.
#
# Identical layout to Scripts/build-skit-release.sh but skips release-mode
# optimization (5-15 minute SwiftSyntax compile → ~10 seconds). Use this when
# you want to exercise the end-to-end DSL→Swift transformation locally; use
# the release script when staging an actual release bundle.
#
# Output: .build/skit-debug/{skit, lib/}

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS-only. Linux uses a parallel flow." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/.build/skit-debug"
PACKAGE_FILE="$REPO_ROOT/Package.swift"
PACKAGE_BACKUP="$(mktemp)"

cleanup() {
  if [[ -s "$PACKAGE_BACKUP" ]]; then
    cp "$PACKAGE_BACKUP" "$PACKAGE_FILE"
  fi
  rm -f "$PACKAGE_BACKUP"
}
trap cleanup EXIT

cp "$PACKAGE_FILE" "$PACKAGE_BACKUP"

echo "==> Flipping SyntaxKit library to type: .dynamic (temporary)"
python3 - "$PACKAGE_FILE" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1])
src = p.read_text()
new_block = '    .library(\n      name: "SyntaxKit",\n      type: .dynamic,\n      targets: ["SyntaxKit"]\n    ),'
if new_block in src:
    print("Package.swift already has type: .dynamic — leaving as-is.")
    sys.exit(0)
old_block = '    .library(\n      name: "SyntaxKit",\n      targets: ["SyntaxKit"]\n    ),'
if old_block not in src:
    sys.exit("Package.swift: expected SyntaxKit library product block not found")
p.write_text(src.replace(old_block, new_block, 1))
PY

cd "$REPO_ROOT"

echo "==> swift build --product skit"
swift build --product skit

echo "==> swift build --product SyntaxKit"
swift build --product SyntaxKit

BUILD_DIR="$(ls -d .build/*-apple-macosx*/debug 2>/dev/null | head -1)"
if [[ -z "$BUILD_DIR" ]]; then
  echo "Could not locate debug build dir under .build/<triple>/debug" >&2
  exit 1
fi

echo "==> Staging $OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/lib"

cp "$BUILD_DIR/skit" "$OUTPUT_DIR/skit"
cp "$BUILD_DIR/libSyntaxKit.dylib" "$OUTPUT_DIR/lib/"
cp -r "$BUILD_DIR/Modules/." "$OUTPUT_DIR/lib/"
cp -r "$REPO_ROOT/.build/checkouts/swift-syntax/Sources/_SwiftSyntaxCShims/include" \
      "$OUTPUT_DIR/lib/_SwiftSyntaxCShims-include"

install_name_tool -id "@rpath/libSyntaxKit.dylib" "$OUTPUT_DIR/lib/libSyntaxKit.dylib" 2>/dev/null || true

swift --version > "$OUTPUT_DIR/lib/swift-version.txt"

echo
echo "==> Debug bundle ready at $OUTPUT_DIR"
echo "==> Try it:"
echo "  $OUTPUT_DIR/skit Examples/Completed/card_game/dsl.swift --no-cache"
