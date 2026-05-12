# skitrun

> **Status:** research POC for [issue #154](https://github.com/brightdigit/SyntaxKit/issues/154). Shape may change; do not pin tooling to it yet. Design lives at [`Docs/research/codegen-cli-design.md`](../../Docs/research/codegen-cli-design.md); the 7-step build-up is documented step-by-step under [`Docs/research/poc-step{1..7}-results.md`](../../Docs/research/).

A CLI that takes a *pure SyntaxKit DSL* input file, wraps it in a `Group { … }` closure, spawns `swift` to evaluate it, and writes the rendered Swift source to stdout (or a file). No `print`, no `@main`, no boilerplate in your input — just DSL expressions.

```
skitrun Input.swift                 # render to stdout
skitrun Input.swift -o Out.swift    # render to a file
skitrun InputDir/ -o OutDir/        # walk **/*.swift, mirror to OutDir/
```

## Quick start

```bash
# Build a portable bundle (the script flips the SyntaxKit library to
# .dynamic, then bundles dylib + modules + C-shims headers next to skitrun).
Docs/research/poc-step4-release.sh
# → .build/skitrun-release/{skitrun, lib/}

cat > /tmp/Person.swift <<'SWIFT'
Struct("Person") {
    Variable(.let, name: "name", type: "String")
    Variable(.let, name: "age", type: "Int")
}
SWIFT

.build/skitrun-release/skitrun /tmp/Person.swift
```

The bundle is self-contained: `cp -r .build/skitrun-release ~/anywhere/` and `~/anywhere/skitrun-release/skitrun <input>` works zero-config.

## Input file shape

Top-level expressions form an implicit `@CodeBlockBuilder` body. `import` declarations at the top are hoisted into the wrapper. Anything else (`Struct(…)`, `Enum(…)`, helper calls, …) becomes the builder's content.

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

Shared codegen utilities live in a `Helpers/` directory anywhere up-tree from the input. `skitrun` walks up from the input file (or directory) looking for one. Sources are pre-compiled into `libSyntaxKitHelpers.{dylib,so}` once and cached by content hash:

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

Two layers, both keyed on content + toolchain + dylib stamp + `SKITRUN_*`/`SYNTAXKIT_*` env vars. Live under `~/Library/Caches/com.brightdigit.SyntaxKit/` on macOS, `$XDG_CACHE_HOME/syntaxkit` (or `~/.cache/syntaxkit`) on Linux.

| Layer | Path | What it skips on hit |
| --- | --- | --- |
| Helpers | `helpers/<sha>/` | the `swiftc` compile of `Helpers/*.swift` |
| Output | `outputs/<sha>/output.swift` | the `swift` spawn for an input |

Output cache hit ≈ 0.14s on macOS (no spawn at all); cold miss matches the warm `swift` script-mode baseline (~0.5s). Force a miss with `--no-cache`.

## Flag reference

| Flag | Default | Meaning |
| --- | --- | --- |
| `-o, --output <path>` | stdout | Output file (single-file mode) or directory (folder mode). |
| `--lib <dir>` | auto | Directory containing `libSyntaxKit.{dylib,so}` + module files. Search order when omitted: `$SKITRUN_LIB_DIR` → `<bin-dir>/lib/` → `<bin-dir>/../lib/skitrun/`. |
| `--helpers <dir>` | walk-up | Explicit `Helpers/` directory. |
| `--no-helpers` | (off) | Skip helpers discovery entirely. |
| `--no-cache` | (off) | Skip the output cache; always spawn `swift`. |
| `--timeout <s>` | `60` | Per-input timeout for the spawned `swift` (SIGTERM → 5s → SIGKILL). On expiry the file exits with code 124. Pass `0` to disable. |

## Platform notes

- **macOS:** primary target. All seven POC steps run via the scripts in `Docs/research/`.
- **Linux:** verified in `swift:6.0-jammy/aarch64` via [`Docs/research/poc-step7.sh`](../../Docs/research/poc-step7.sh) (self-reruns inside Docker). Requires `swift-crypto` instead of CryptoKit; install-name flag is Mach-O specific and skipped on Linux.
- **Windows:** not attempted.

A known Linux gotcha: `Foundation.Process.waitUntilExit()` hangs on already-exited children on `swift:6.0-jammy/aarch64`. Workaround in `Helpers.swift` / `Main.swift`: `terminationHandler` + `DispatchSemaphore`. See [`poc-step7-results.md`](../../Docs/research/poc-step7-results.md) for the full reproducer.

## Open scope decisions

Not blocking but on the table — see [`codegen-cli-design.md` §7](../../Docs/research/codegen-cli-design.md#7-what-we-still-need-to-verify):

- Timeouts on the child `swift` process (60s default + SIGTERM/SIGKILL grace).
- `@main` / attribute behavior in `swift` script-mode beyond the simple cases tested.
- Multi-file outputs from a single input (out of scope for v1).
- Sandboxing (out of scope; threat model = "you ran your own code").
- HTTP/server form for warm-interpreter reuse (post-CLI follow-up).
