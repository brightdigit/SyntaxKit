# skit

A CLI for SyntaxKit. Two verbs:

```
skit run Input.swift          # render a SyntaxKit DSL file into Swift source
skit run Input.swift -o Out.swift
skit run InputDir/ -o OutDir/ # walk **/*.swift and mirror rendered output
skit parse < Input.swift      # parse Swift source into a JSON syntax tree
```

`run` is the default subcommand, so `skit Input.swift` is shorthand for `skit run Input.swift`.

## Quick start

```bash
# Build a self-contained release bundle (binary + dylib + swiftmodules).
Scripts/build-skit-release.sh
# → .build/skit-release/{skit, lib/}

cat > /tmp/Person.swift <<'SWIFT'
Struct("Person") {
    Variable(.let, name: "name", type: "String")
    Variable(.let, name: "age", type: "Int")
}
SWIFT

.build/skit-release/skit /tmp/Person.swift
```

The bundle is portable: `cp -r .build/skit-release ~/anywhere/` and `~/anywhere/skit-release/skit <input>` works zero-config.

## Input file shape

`skit run` wraps each input in an implicit `Group { … }` builder. Top-level expressions become the builder's content; `import` declarations at the top are hoisted into the wrapper.

```swift
// Models.swift
import SyntaxKitHelpers   // optional — only if a Helpers/ dir is present

equatableModel("Person", fields: [
    ("name", "String"),
    ("age", "Int"),
])
```

What *won't* work inside the input: top-level `let`/`var` outside the builder DSL, `@main`, `print` (the wrapper adds its own). Result-builder closure rules apply.

## Helpers

Shared codegen utilities live in a `Helpers/` directory anywhere up-tree from the input. `skit` walks up from the input file (or directory) looking for one. Sources are pre-compiled into `libSyntaxKitHelpers.{dylib,so}` once and cached by content hash:

```
project/
├── Helpers/
│   └── Models.swift     # public func equatableModel(_:fields:) -> any CodeBlock
└── inputs/
    ├── Person.swift     # imports SyntaxKitHelpers, calls equatableModel(...)
    └── Pet.swift        # same
```

Files prefixed with `_` are skipped (convention for private helpers within helpers). The helper module name is hard-coded to `SyntaxKitHelpers`.

Force-disable: `--no-helpers`. Override location: `--helpers <dir>`.

## Caches

Two layers, both keyed on content + toolchain + dylib stamp + `SKIT_*`/`SYNTAXKIT_*` env vars. Live under `~/Library/Caches/com.brightdigit.SyntaxKit/` on macOS, `$XDG_CACHE_HOME/syntaxkit` (or `~/.cache/syntaxkit`) on Linux.

| Layer   | Path                          | What it skips on hit                          |
| ------- | ----------------------------- | --------------------------------------------- |
| Helpers | `helpers/<sha>/`              | the `swiftc` compile of `Helpers/*.swift`     |
| Output  | `outputs/<sha>/output.swift`  | the `swift` spawn for an input                |

Output cache hit is roughly ~0.14s on macOS (no spawn at all); cold miss matches the warm `swift` script-mode baseline (~0.5s). Force a miss with `--no-cache`.

## Flag reference (`skit run`)

| Flag                    | Default | Meaning                                                                                                                                                  |
| ----------------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-o, --output <path>`   | stdout  | Output file (single-file mode) or directory (folder mode).                                                                                               |
| `--lib <dir>`           | auto    | Directory containing `libSyntaxKit.{dylib,so}` + module files. Search order when omitted: `$SKIT_LIB_DIR` → `<bin-dir>/lib/` → `<bin-dir>/../lib/skit/`. |
| `--helpers <dir>`       | walk-up | Explicit `Helpers/` directory.                                                                                                                           |
| `--no-helpers`          | (off)   | Skip helpers discovery entirely.                                                                                                                         |
| `--no-cache`            | (off)   | Skip the output cache; always spawn `swift`.                                                                                                             |
| `--timeout <s>`         | `60`    | Per-input timeout for the spawned `swift` (SIGTERM → 5s → SIGKILL). On expiry the file exits with code 124. Pass `0` to disable.                         |
| `--no-toolchain-check`  | (off)   | Skip the startup check that compares `lib/swift-version.txt` to `swift --version`. swiftmodules aren't reliably compatible across compiler versions; on mismatch skit refuses to spawn `swift` and points at the rebuild script. Auto-rebuild fallback tracked in [#157](https://github.com/brightdigit/SyntaxKit/issues/157). |

## Platform notes

- **macOS** — primary target. All build/release/test flows in `Scripts/`.
- **Linux** — verified on `swift:6.0-jammy/aarch64`. Requires `swift-crypto` instead of CryptoKit (we depend on it). The Mach-O `install_name` step in `Scripts/build-skit-release.sh` is macOS-specific and skipped on Linux.
- **Windows** — not supported.

Known Linux gotcha: `Foundation.Process.waitUntilExit()` hangs on already-exited children on `swift:6.0-jammy/aarch64`. `Runner.swift` and `Helpers.swift` work around it with `terminationHandler` + `DispatchSemaphore`.

## Deeper dive

For the architecture, design decisions, and trade-offs see [`Docs/skit.md`](../../Docs/skit.md).
