#!/usr/bin/env bash
#
# POC step 7: Linux smoke test for skitrun.
#
# Runs inside a swift:6.0-jammy container. Builds skitrun, stages a
# runtime lib/ next to it (libSyntaxKit.so + Modules + _SwiftSyntaxCShims
# headers), then exercises single-file mode, helpers, and the output
# cache — the same flows POC steps 5 and 6 verified on macOS.
#
# Usage (from macOS host or Linux host with docker):
#   Docs/research/poc-step7.sh
#
# Override the image with $SKITRUN_LINUX_IMAGE.
#
# To save time across runs, the script uses .build-linux/ as a separate
# build directory so the host's .build/ stays clean and SwiftSyntax
# doesn't re-download on every invocation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
IMAGE="${SKITRUN_LINUX_IMAGE:-swift:6.0-jammy}"

if [[ ! -f /.dockerenv ]]; then
  # ---- Host side: invoke ourselves inside the swift container. ----
  if ! command -v docker >/dev/null; then
    echo "docker is required for POC step 7" >&2
    exit 1
  fi
  echo "==> Running POC step 7 inside $IMAGE"
  exec docker run --rm -t \
    -v "$REPO_ROOT:/workspace" \
    -w /workspace \
    -e SKITRUN_INSIDE_DOCKER=1 \
    "$IMAGE" \
    /workspace/Docs/research/poc-step7.sh
fi

# ---- Container side: do the real work. ----

PACKAGE_FILE="Package.swift"
PACKAGE_BACKUP="$(mktemp)"
cleanup() {
  if [[ -s "$PACKAGE_BACKUP" ]]; then
    cp "$PACKAGE_BACKUP" "$PACKAGE_FILE"
  fi
  rm -f "$PACKAGE_BACKUP"
}
trap cleanup EXIT

cp "$PACKAGE_FILE" "$PACKAGE_BACKUP"

echo "==> swift --version"
swift --version

echo
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

echo
echo "==> swift build (build path: .build-linux)"
swift build --build-path .build-linux

BUILD_DIR="$(ls -d .build-linux/*-unknown-linux-gnu/debug 2>/dev/null | head -1)"
if [[ -z "$BUILD_DIR" ]]; then
  echo "Could not locate Linux build dir under .build-linux/" >&2
  ls -la .build-linux/ || true
  exit 1
fi

POC_DIR=/tmp/syntaxkit-poc-step7
DEMO_DIR="$POC_DIR/demo"
OUTPUT_CACHE="$HOME/.cache/syntaxkit/outputs"

rm -rf "$POC_DIR" "$HOME/.cache/syntaxkit"
mkdir -p "$POC_DIR/lib" "$DEMO_DIR/Helpers"

cp "$BUILD_DIR/skitrun" "$POC_DIR/skitrun"
cp "$BUILD_DIR/libSyntaxKit.so" "$POC_DIR/lib/"
cp -r "$BUILD_DIR/Modules/." "$POC_DIR/lib/"
cp -r .build-linux/checkouts/swift-syntax/Sources/_SwiftSyntaxCShims/include \
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

cat > "$DEMO_DIR/Input.swift" <<'SWIFT'
import SyntaxKitHelpers

equatableModel("Person", fields: [
    ("name", "String"),
    ("age", "Int"),
])
SWIFT

echo
echo "==> Cold run (helpers compile + output cache miss):"
time "$POC_DIR/skitrun" "$DEMO_DIR/Input.swift"

echo
echo "==> Warm run (output cache hit, no swift spawn):"
time "$POC_DIR/skitrun" "$DEMO_DIR/Input.swift" >/dev/null

echo
echo "==> --no-cache (swift spawn, helpers reused):"
time "$POC_DIR/skitrun" --no-cache "$DEMO_DIR/Input.swift" >/dev/null

echo
echo "==> Output cache entries:"
find "$OUTPUT_CACHE" -maxdepth 2 -type f 2>/dev/null | sed "s|$OUTPUT_CACHE|<cache>|" | sort

echo
echo "==> Linux smoke test passed."
