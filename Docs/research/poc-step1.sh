#!/usr/bin/env bash
#
# POC step 1 reproducer for issue #154.
# Run from anywhere; resolves the repo root from its own location.
#
# What it does:
#   1. Backs up Package.swift, flips the SyntaxKit library to type: .dynamic.
#   2. swift build (produces libSyntaxKit.dylib).
#   3. Stages dylib + swiftmodules + _SwiftSyntaxCShims headers into /tmp/syntaxkit-poc/lib/.
#   4. Writes a pure-DSL Input.swift and a hand-rolled Input.wrapped.swift.
#   5. Runs the wrapped script once cold + three times warm, printing timings.
#   6. Restores Package.swift on exit (even on failure).

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This reproducer is macOS-only. Linux smoke test is POC step 7." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
POC_DIR="/tmp/syntaxkit-poc"
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
    sys.exit("Package.swift: expected SyntaxKit library product block not found — has Package.swift changed shape?")
p.write_text(src.replace(old, new, 1))
PY

cd "$REPO_ROOT"
echo "==> swift build"
swift build

BUILD_DIR="$(ls -d .build/*-apple-macosx*/debug 2>/dev/null | head -1 || true)"
if [[ -z "$BUILD_DIR" ]]; then
  echo "Could not locate .build/<triple>/debug" >&2
  exit 1
fi

echo "==> Staging $POC_DIR/lib/"
rm -rf "$POC_DIR"
mkdir -p "$POC_DIR/lib"
cp "$BUILD_DIR/libSyntaxKit.dylib" "$POC_DIR/lib/"
cp -r "$BUILD_DIR/Modules/." "$POC_DIR/lib/"
cp -r ".build/checkouts/swift-syntax/Sources/_SwiftSyntaxCShims/include" \
      "$POC_DIR/lib/_SwiftSyntaxCShims-include"

cat > "$POC_DIR/Input.swift" <<'SWIFT'
// Pure-DSL input. No print, no @main, no boilerplate.
import SyntaxKit  // optional; only for IDE autocomplete

Struct("Person") {
    Variable(.let, name: "name", type: "String")
    Variable(.let, name: "age", type: "Int")
}

Struct("Pet") {
    Variable(.let, name: "kind", type: "String")
}
SWIFT

cat > "$POC_DIR/Input.wrapped.swift" <<'SWIFT'
import SyntaxKit

let __syntaxkit_root = Group {
    Struct("Person") {
        Variable(.let, name: "name", type: "String")
        Variable(.let, name: "age", type: "Int")
    }
    Struct("Pet") {
        Variable(.let, name: "kind", type: "String")
    }
}

print(__syntaxkit_root.generateCode())
SWIFT

cd "$POC_DIR"

SWIFT_ARGS=(
  -I lib -L lib -lSyntaxKit
  -Xcc -I -Xcc lib/_SwiftSyntaxCShims-include
  -Xlinker -rpath -Xlinker "$POC_DIR/lib"
  Input.wrapped.swift
)

echo
echo "==> Cold run (full output + timing):"
/usr/bin/time -p xcrun swift "${SWIFT_ARGS[@]}"

echo
echo "==> Warm runs (timings only, output discarded):"
for _ in 1 2 3; do
  /usr/bin/time -p xcrun swift "${SWIFT_ARGS[@]}" >/dev/null
done

echo
echo "==> Done. Staging dir kept at $POC_DIR for further poking."
