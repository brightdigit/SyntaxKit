#!/usr/bin/env bash
#
# POC step 4: build a self-contained skitrun release bundle.
#
# Output: .build/skitrun-release/
#   skitrun                        ← the CLI binary
#   lib/
#     libSyntaxKit.dylib           ← release + strip -x
#     *.swiftmodule                ← SyntaxKit + transitively re-exported modules
#     _SwiftSyntaxCShims-include/  ← C-shims headers (module map + .h files)
#
# Once produced, the binary is portable: copy the whole .build/skitrun-release/
# directory anywhere, and `./skitrun-release/skitrun <input>` Just Works — no
# flags, no env vars, no SyntaxKit checkout required.

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS-only for now. Linux smoke test is POC step 7." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/.build/skitrun-release"
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
old = '    .library(\n      name: "SyntaxKit",\n      targets: ["SyntaxKit"]\n    ),'
new = '    .library(\n      name: "SyntaxKit",\n      type: .dynamic,\n      targets: ["SyntaxKit"]\n    ),'
if old not in src:
    sys.exit("Package.swift: expected SyntaxKit library product block not found")
p.write_text(src.replace(old, new, 1))
PY

cd "$REPO_ROOT"

echo "==> swift build -c release --product skitrun"
swift build -c release --product skitrun

# skitrun doesn't depend on SyntaxKit (it spawns swift on user input that
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

cp "$BUILD_DIR/skitrun" "$OUTPUT_DIR/skitrun"
cp "$BUILD_DIR/libSyntaxKit.dylib" "$OUTPUT_DIR/lib/"
strip -x "$OUTPUT_DIR/lib/libSyntaxKit.dylib"
cp -r "$BUILD_DIR/Modules/." "$OUTPUT_DIR/lib/"
cp -r "$REPO_ROOT/.build/checkouts/swift-syntax/Sources/_SwiftSyntaxCShims/include" \
      "$OUTPUT_DIR/lib/_SwiftSyntaxCShims-include"

# Ensure the dylib's install_name uses @rpath so it's portable.
install_name_tool -id "@rpath/libSyntaxKit.dylib" "$OUTPUT_DIR/lib/libSyntaxKit.dylib" 2>/dev/null || true

# Stamp the bundle with the build toolchain. skitrun compares this against
# the user's `swift --version` at startup and refuses to spawn `swift` if the
# swiftmodule wouldn't load (see Sources/skitrun/Main.swift). Issue #157 will
# replace the refusal with an auto-rebuild fallback.
swift --version > "$OUTPUT_DIR/lib/swift-version.txt"

BINARY_SIZE=$(ls -lh "$OUTPUT_DIR/skitrun" | awk '{print $5}')
DYLIB_SIZE=$(ls -lh "$OUTPUT_DIR/lib/libSyntaxKit.dylib" | awk '{print $5}')
TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" | awk '{print $1}')

echo
echo "==> Release bundle ready:"
echo "  Binary:  $BINARY_SIZE"
echo "  Dylib:   $DYLIB_SIZE"
echo "  Total:   $TOTAL_SIZE"
echo
echo "==> Try it:"
echo "  $OUTPUT_DIR/skitrun <some-input.swift>"
