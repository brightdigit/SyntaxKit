# POC Step 4 — Results

> Companion to [`codegen-cli-design.md`](./codegen-cli-design.md) §6 step 4. Goal: produce a self-contained `skitrun` release bundle so users don't need a SyntaxKit checkout or `Docs/research/poc-step1.sh`. The binary finds its own `lib/` directory.

## What landed

1. **`resolveLibPath(override:)` in `Sources/skitrun/Main.swift`.** Search order:
   1. `--lib <dir>` flag
   2. `$SKITRUN_LIB_DIR` env var
   3. `<binary-dir>/lib/` — same-directory layout (the release bundle ships this way)
   4. `<binary-dir>/../lib/skitrun/` — Homebrew layout (`bin/skitrun` ↔ `lib/skitrun/`)

   When none match, the CLI errors with a message enumerating all four paths and pointing at this script. The `/tmp/syntaxkit-poc/lib` fallback is gone.

2. **`Docs/research/poc-step4-release.sh`.** Builds a self-contained bundle:
   ```
   .build/skitrun-release/
     skitrun                       ← the CLI binary
     lib/
       libSyntaxKit.dylib          ← release + strip -x
       *.swiftmodule               ← SyntaxKit + transitively re-exported modules
       _SwiftSyntaxCShims-include/ ← C-shims headers
   ```
   Same trap-based Package.swift backup/restore as `poc-step1.sh`. `install_name_tool -id @rpath/libSyntaxKit.dylib` ensures the dylib install name is portable.

## Verified flows

Built bundle → copied to three unrelated locations → all worked with no flags, no env vars, no SyntaxKit checkout:

1. **Same-directory layout.** `cp -r .build/skitrun-release /tmp/portable && /tmp/portable/skitrun Input.swift` → correct output.
2. **Homebrew layout.** `bin/skitrun + lib/skitrun/` arrangement → correct output.
3. **Error case.** `skitrun` alone in `/tmp/lonely/` (no lib anywhere) → clear diagnostic:
   ```
   Could not locate SyntaxKit lib directory. Looked for:
     1. --lib <dir>           (not provided)
     2. $SKITRUN_LIB_DIR       (not set)
     3. <binary-dir>/lib/      (not found)
     4. <binary-dir>/../lib/skitrun/  (not found)
   ```
4. **Folder mode** from the portable bundle works end-to-end with partial-failure semantics intact.

## Bundle weight

| Component | Size |
| --- | ---: |
| `skitrun` (binary) | 17 MB |
| `libSyntaxKit.dylib` (release + stripped) | 9.3 MB |
| `lib/*` (modules + headers + dylib) | ~28 MB |
| **Total bundle** | **45 MB** |

The 17 MB binary is unexpectedly heavy: it links SwiftSyntax statically because `skitrun` uses SwiftSyntax directly for parsing input files. So SwiftSyntax ships **twice** — once statically inside `skitrun`, once dynamically as part of the SyntaxKit dylib stack. Worth a follow-up: make `skitrun` itself dlopen SyntaxKit / share a dynamic SwiftSyntax with the dylib path. For v1 this is acceptable but is the largest single thing standing between the CLI and a "feels small" download.

## What's next

Step 5: helpers directory. Today users can `import Foundation` and `import SyntaxKit` from input files; step 5 lets them factor reusable codegen into a `Helpers/` directory that gets pre-compiled into `lib<HelpersName>.dylib` and made importable from inputs. Modest engineering, but the first time `skitrun` itself invokes `swiftc` rather than `swift` (the helpers compile, distinct from the input run). See [`codegen-cli-design.md` §4](./codegen-cli-design.md#4-helpers) for the shape.
