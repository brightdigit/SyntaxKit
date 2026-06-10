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
Scripts/build-skit.sh
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
Struct("Person") {
    Variable(.let, name: "name", type: "String")
    Variable(.let, name: "age", type: "Int")
}
```

What *won't* work inside the input: top-level `let`/`var` outside the builder DSL, `@main`, `print` (the wrapper adds its own). Result-builder closure rules apply.

## Cache

One layer, keyed on content + toolchain + dylib stamp + `SKIT_*`/`SYNTAXKIT_*` env vars. Lives under `~/Library/Caches/com.brightdigit.SyntaxKit/outputs/<sha>/output.swift` on macOS, `$XDG_CACHE_HOME/syntaxkit/outputs/<sha>/output.swift` (or `~/.cache/syntaxkit/outputs/<sha>/output.swift`) on Linux. On hit, `skit` skips the `swift` spawn for an input entirely.

Output cache hit is roughly ~0.14s on macOS (no spawn at all); cold miss matches the warm `swift` script-mode baseline (~0.5s). Force a miss with `--no-cache`.

## Flag reference (`skit run`)

| Flag                    | Default | Meaning                                                                                                                                                  |
| ----------------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-o, --output <path>`   | stdout  | Output file (single-file mode) or directory (folder mode).                                                                                               |
| `--lib <dir>`           | auto    | Directory containing `libSyntaxKit.{dylib,so}` + module files. Search order when omitted: `$SKIT_LIB_DIR` → `<bin-dir>/lib/` → `<bin-dir>/../lib/skit/`. |
| `--no-cache`            | (off)   | Skip the output cache; always spawn `swift`.                                                                                                             |
| `--timeout <s>`         | `60`    | Per-input timeout for the spawned `swift` (SIGTERM → 5s → SIGKILL). On expiry the file exits with code 124. Pass `0` to disable.                         |
| `--no-toolchain-check`  | (off)   | Skip the startup check that compares `lib/swift-version.txt` to `swift --version`. swiftmodules aren't reliably compatible across compiler versions; on mismatch skit refuses to spawn `swift` and points at the rebuild script. Auto-rebuild fallback tracked in [#157](https://github.com/brightdigit/SyntaxKit/issues/157). |

## Platform notes

- **macOS** — primary target. All build/release/test flows in `Scripts/`.
- **Linux** — verified on `swift:6.0-jammy/aarch64`. The Mach-O `install_name` step in `Scripts/build-skit.sh` is macOS-specific and skipped on Linux.
- **Windows** — not supported.

Known Linux gotcha: `Foundation.Process.waitUntilExit()` hangs on already-exited children on `swift:6.0-jammy/aarch64`. `Runner.swift` works around it with `terminationHandler` + `DispatchSemaphore`.

## Deeper dive

- [`Docs/skit.md`](../../Docs/skit.md) — architecture, design decisions, trade-offs.
