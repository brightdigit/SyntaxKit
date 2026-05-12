#!/usr/bin/env bash
#
# POC step 5 demo: Helpers/ discovery + compile + import in input scripts.
#
# Builds skitrun, stages a runtime lib/ next to it, then runs skitrun against
# a demo project that uses `import SyntaxKitHelpers`. Demonstrates:
#   1. Cold path  — Helpers/ compiles to libSyntaxKitHelpers.dylib.
#   2. Warm path  — second invocation reuses the cached helpers dylib.
#   3. Folder mode — skitrun ignores Helpers/ when walking the input tree.
#   4. --no-helpers — disables discovery; the import then fails as expected.

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS-only. Linux smoke test is POC step 7." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
POC_DIR="/tmp/syntaxkit-poc-step5"
DEMO_DIR="$POC_DIR/demo"
CACHE_DIR="$HOME/Library/Caches/com.brightdigit.SyntaxKit/helpers"
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

echo "==> swift build"
swift build

BUILD_DIR="$(ls -d .build/*-apple-macosx*/debug 2>/dev/null | head -1)"
if [[ -z "$BUILD_DIR" ]]; then
  echo "Could not locate .build/<triple>/debug" >&2
  exit 1
fi

echo "==> Staging $POC_DIR"
rm -rf "$POC_DIR"
mkdir -p "$POC_DIR/lib" "$DEMO_DIR/Helpers" "$DEMO_DIR/inputs"

cp "$BUILD_DIR/skitrun" "$POC_DIR/skitrun"
cp "$BUILD_DIR/libSyntaxKit.dylib" "$POC_DIR/lib/"
cp -r "$BUILD_DIR/Modules/." "$POC_DIR/lib/"
cp -r "$REPO_ROOT/.build/checkouts/swift-syntax/Sources/_SwiftSyntaxCShims/include" \
      "$POC_DIR/lib/_SwiftSyntaxCShims-include"

cat > "$DEMO_DIR/Helpers/Models.swift" <<'SWIFT'
import SyntaxKit

public func equatableModel(
    _ name: String,
    fields: [(name: String, type: String)]
) -> any CodeBlock {
    Struct(name) {
        for field in fields {
            Variable(.let, name: field.name, type: field.type)
        }
    }.inherits("Equatable")
}
SWIFT

cat > "$DEMO_DIR/inputs/Person.swift" <<'SWIFT'
import SyntaxKitHelpers

equatableModel("Person", fields: [
    ("name", "String"),
    ("age", "Int"),
])
SWIFT

cat > "$DEMO_DIR/inputs/Pet.swift" <<'SWIFT'
import SyntaxKitHelpers

equatableModel("Pet", fields: [
    ("kind", "String"),
    ("owner", "String"),
])
SWIFT

echo "==> Clearing helpers cache to force cold compile"
rm -rf "$CACHE_DIR"

echo
echo "==> Cold run (helpers compile from scratch):"
/usr/bin/time -p "$POC_DIR/skitrun" "$DEMO_DIR/inputs/Person.swift"

echo
echo "==> Warm run (helpers cache hit):"
/usr/bin/time -p "$POC_DIR/skitrun" "$DEMO_DIR/inputs/Person.swift" >/dev/null

echo
echo "==> Cached helper artifacts:"
find "$CACHE_DIR" -maxdepth 3 -type f | sed "s|$CACHE_DIR|<cache>|" | sort

echo
echo "==> Folder mode (Helpers/ excluded from input enumeration):"
rm -rf "$POC_DIR/out"
"$POC_DIR/skitrun" "$DEMO_DIR" -o "$POC_DIR/out"
echo "  Generated files:"
find "$POC_DIR/out" -type f | sed "s|$POC_DIR/|  |"

echo
echo "==> --no-helpers should fail with an unresolved import:"
if "$POC_DIR/skitrun" --no-helpers "$DEMO_DIR/inputs/Person.swift" >/dev/null 2>&1; then
  echo "FAIL: --no-helpers should have errored" >&2
  exit 1
else
  echo "  ✓ skitrun returned non-zero as expected"
fi

echo
echo "==> Done. Demo project kept at $DEMO_DIR; cache at $CACHE_DIR."
