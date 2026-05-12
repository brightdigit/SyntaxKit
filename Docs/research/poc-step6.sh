#!/usr/bin/env bash
#
# POC step 6 demo: rendered-output cache. skitrun skips the `swift` spawn
# when input + helpers + toolchain are unchanged.
#
# Builds skitrun, stages a runtime lib next to it, runs an input, then
# replays it three ways:
#   1. with cache    — should be near-instant (no swift spawn)
#   2. --no-cache    — always spawns swift
#   3. mutated input — invalidates the cache key, falls back to swift

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS-only. Linux smoke test is POC step 7." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
POC_DIR="/tmp/syntaxkit-poc-step6"
DEMO_DIR="$POC_DIR/demo"
OUTPUT_CACHE="$HOME/Library/Caches/com.brightdigit.SyntaxKit/outputs"
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
mkdir -p "$POC_DIR/lib" "$DEMO_DIR"

cp "$BUILD_DIR/skitrun" "$POC_DIR/skitrun"
cp "$BUILD_DIR/libSyntaxKit.dylib" "$POC_DIR/lib/"
cp -r "$BUILD_DIR/Modules/." "$POC_DIR/lib/"
cp -r "$REPO_ROOT/.build/checkouts/swift-syntax/Sources/_SwiftSyntaxCShims/include" \
      "$POC_DIR/lib/_SwiftSyntaxCShims-include"

cat > "$DEMO_DIR/Input.swift" <<'SWIFT'
Struct("Person") {
    Variable(.let, name: "name", type: "String")
    Variable(.let, name: "age", type: "Int")
}
SWIFT

echo "==> Clearing output cache to force a cold run"
rm -rf "$OUTPUT_CACHE"

echo
echo "==> Cold run (cache miss → swift spawn → store):"
/usr/bin/time -p "$POC_DIR/skitrun" "$DEMO_DIR/Input.swift" >/dev/null

echo
echo "==> Warm run (cache hit → no swift spawn):"
/usr/bin/time -p "$POC_DIR/skitrun" "$DEMO_DIR/Input.swift" >/dev/null

echo
echo "==> --no-cache (always spawn swift, even with cache present):"
/usr/bin/time -p "$POC_DIR/skitrun" --no-cache "$DEMO_DIR/Input.swift" >/dev/null

echo
echo "==> Output cache contents:"
find "$OUTPUT_CACHE" -maxdepth 3 -type f | sed "s|$OUTPUT_CACHE|<cache>|" | sort

echo
echo "==> Mutating input invalidates the cache:"
cat > "$DEMO_DIR/Input.swift" <<'SWIFT'
Struct("Person") {
    Variable(.let, name: "name", type: "String")
    Variable(.let, name: "age", type: "Int")
    Variable(.let, name: "email", type: "String")
}
SWIFT
/usr/bin/time -p "$POC_DIR/skitrun" "$DEMO_DIR/Input.swift" >/dev/null

echo
echo "==> Warm run after mutation:"
/usr/bin/time -p "$POC_DIR/skitrun" "$DEMO_DIR/Input.swift" >/dev/null

echo
echo "==> Cache now contains two distinct keys:"
find "$OUTPUT_CACHE" -maxdepth 1 -mindepth 1 -type d | wc -l | xargs -I {} echo "  {} cache entries"

echo
echo "==> Done. Cache at $OUTPUT_CACHE."
