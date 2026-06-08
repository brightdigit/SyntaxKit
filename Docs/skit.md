# `skit` — a SyntaxKit CLI for config-driven Swift codegen

`skit` is a small CLI that takes a SyntaxKit DSL file as input and writes Swift source out the other side. The vision: pure data — JSON, YAML, your own format — drives a manifest written in the SyntaxKit DSL, and `skit` materializes it into idiomatic Swift you check in alongside everything else. Less hand-maintenance, fewer drift bugs.

This doc walks through how `skit` is built. Two verbs, one wrap-and-spawn pipeline, an output cache, and a careful toolchain story underneath. Where there are sharp edges, this doc names them.

## Two verbs

```
skit run Input.swift          # SyntaxKit DSL → Swift source on stdout
skit run Input.swift -o Out.swift
skit run InputDir/ -o OutDir/ # walk **/*.swift and mirror rendered output
skit parse < Input.swift      # Swift source → JSON syntax tree
```

`run` is the default subcommand. `skit Input.swift` is shorthand for `skit run Input.swift`. `parse` is a one-shot for the inverse direction (Swift source → SwiftSyntax tree as JSON) — useful for tooling that wants to introspect existing code.

The remainder of this doc is about `run`, which is where the interesting design decisions live.

## How `skit run` works

A `.swift` input file looks like a SyntaxKit DSL expression at the top level:

```swift
// Models.swift
Struct("Person") {
    Variable(.let, name: "name", type: "String")
    Variable(.let, name: "age", type: "Int")
}
```

The input is not a complete Swift program. It has no `@main`, no `print`, no `let root = …`. `skit run` adds the boilerplate by wrapping the input in a `Group { … }` builder and a top-level `print` that renders the result:

```swift
// What `skit run` writes to a temp file before spawning `swift`:
import SyntaxKit

let __skit_root = Group {
#sourceLocation(file: "/path/to/Models.swift", line: 3)
Struct("Person") {
    Variable(.let, name: "name", type: "String")
    Variable(.let, name: "age", type: "Int")
}
#sourceLocation()
}

print(__skit_root.generateCode())
```

`skit` then spawns `swift` (the script-mode interpreter, not `swiftc`) on this wrapped file, captures stdout, and writes the result to the user's chosen output target.

Three things deserve a closer look:

**Imports get hoisted.** The wrapper has to start with `import SyntaxKit` so the DSL types are available. Any additional `import`s the user writes need to live at the top of the file, not inside `Group { … }`. `skit` parses the input with SwiftSyntax, peels off the leading `import` declarations, and lifts them into the wrapper preamble. Anything else (declarations, expressions, top-level types) stays in the body.

**`#sourceLocation` keeps diagnostics readable.** When the spawned `swift` emits a compile error, it reports a line number in the wrapped temp file, which is meaningless to the user. The `#sourceLocation` directive remaps body diagnostics back to the original input path and line. Errors in the wrapper preamble (the `import` block, the `Group { … }` opening) still reference the temp file — `skit` rewrites occurrences of the temp path in stderr to the input path as a fallback, so users see something coherent.

**`swift` runs in script mode.** Running `swift Input.swift` invokes the Swift interpreter rather than going through `swiftc` + `ld`. Cold-start is around 700ms on macOS; warm spawns are around 110ms. The CLI's hot path leans into this — for batch input via `skit run InputDir/`, we spawn one `swift` per input file in parallel up to the active core count.

## Output cache

One layer, keyed by content hash. Lives under `~/Library/Caches/com.brightdigit.SyntaxKit/outputs/<sha>/output.swift` on macOS, `$XDG_CACHE_HOME/syntaxkit/outputs/<sha>/output.swift` (or `~/.cache/syntaxkit/outputs/<sha>/output.swift`) on Linux. On hit, `skit` skips the `swift` spawn for an input entirely.

The fully-rendered output of an input gets cached by a hash of (input bytes, libSyntaxKit stamp, swift version, sorted `SKIT_*`/`SYNTAXKIT_*` env vars). On hit, total wall time is around 0.14s, dominated by hash + file read. Cold miss matches the warm script-mode baseline (~0.5s).

`--no-cache` skips the cache.

## Toolchain stamping

Pre-compiled Swift modules (`SyntaxKit.swiftmodule`) are tightly coupled to the compiler that built them. Even patch-level differences fail to load:

```
error: module compiled with Swift 6.3 cannot be imported by the Swift 6.3.2 compiler
```

If `skit`'s bundled `lib/SyntaxKit.swiftmodule` doesn't match the user's `swift`, the spawned interpreter emits exactly this diagnostic and refuses to compile the wrapped input. The user is left staring at a cryptic message that doesn't name the actual problem.

`skit` mitigates this by recording the build toolchain at bundle time. `Scripts/build-skit-release.sh` writes `lib/swift-version.txt` containing the output of `swift --version`. On startup, `skit run` reads the stamp and compares it to a freshly-captured local `swift --version`. Three paths:

- **Match.** Proceed silently.
- **Mismatch.** Print a clear error naming both versions and the rebuild command, exit 2. Skip with `--no-toolchain-check`.
- **Missing stamp.** Print a one-line note and proceed. Older bundles built before this check existed shouldn't break.

The comparison is exact-string match. Patch-level drift broke the originating bug, so anything less strict would just defer the failure to the cryptic message we're trying to avoid.

**What this doesn't do**: it doesn't fix the mismatch, just surfaces it. The fix is to re-run the release script with the user's current toolchain. The auto-rebuild path — bundle SyntaxKit sources alongside the prebuilt module and recompile transparently when the stamp doesn't match — is tracked as [issue #157](https://github.com/brightdigit/SyntaxKit/issues/157).

## Timeout watchdog

The spawned `swift` is the only unbounded piece of `skit run`'s hot path. The wrap step is microseconds. The output cache hits or misses in milliseconds. But the spawn itself runs *user code* — and that code is allowed to be arbitrarily slow, recursive, or stuck.

`skit run` defaults to a 60s per-input timeout. On expiry it sends `SIGTERM`, gives a 5s grace, then `SIGKILL`. The wrapped input exits with code 124 — POSIX `timeout(1)`'s convention. `--timeout <s>` overrides the default; `--timeout 0` disables the watchdog entirely (useful for debugging genuinely long codegen).

The implementation is `DispatchSemaphore.wait(timeout: deadline)` paired with a `process.terminationHandler` that signals on child exit. The Linux Foundation `Process.waitUntilExit()` hangs on already-exited children on some configurations, which is why `skit` uses the semaphore-based wait everywhere. Same story for pipe drains — sequential reads after the child exits can deadlock when either pipe (~64 KB buffer on Linux) fills before exit, so both pipes drain concurrently via `DispatchGroup`.

## Sharp edges

### `if`-in-`Group` crashes the Swift type-checker — [#158](https://github.com/brightdigit/SyntaxKit/issues/158)

`CodeBlockBuilderResult` declares all the methods needed for `if`/`else` in a result builder (`buildEither`, `buildOptional`, `buildArray`), but using them surfaces a Swift type-checker bug:

```swift
let _ = Group {
    if true {                    // ← error: failed to produce diagnostic for expression
        Struct("A") { … }
    }
}
```

This is a Swift compiler bug, not a `skit` bug. The workaround is to hoist the conditional into a plain Swift function that uses **plain Swift `if`/`else`** (not a `Group { if … }` body) to return one of two `CodeBlock`s:

```swift
func optionalDebugField(_ include: Bool) -> any CodeBlock {
    if include {
        return Variable(.let, name: "debug", type: "Bool")
    } else {
        return Group {}   // empty Group as the "no-op" branch — there's no
                           // public EmptyCodeBlock type
    }
}

Struct("Config") {
    Variable(.let, name: "name", type: "String")
    optionalDebugField(buildIsDebug)
}
```

The helper function itself can't use `Group { if … }` either — same crash. Plain Swift control flow only.

### `@main` and top-level decl attributes don't work

`@main` and other decl attributes (like top-level `@available`) at the start of the input fail to compile. The wrapper places the user's body inside `Group { … }`, where these attributes try to bind to a function-call expression rather than a declaration. Examples:

```swift
@main                    // ❌ error: expected declaration
Struct("Person") { … }

@available(iOS 17, *)    // ❌ error: expected declaration
Struct("ModernView") { … }
```

The DSL has its own mechanism for attribute attachment — call `.attribute("Published")`, `.attribute("available", arguments: ["iOS 17", "*"])` on the `Variable`/`Struct`/etc. — which renders the attribute in the *output*, not on the DSL expression itself. That's the path users should take.

### Comments don't carry through

Swift comments in the input file (`// MARK: - Models`, block comments, inline `//` after a DSL line) don't render to the output. The input's comments are *only* for the input's author. To emit a comment in the rendered code, attach it to a `CodeBlock` via `.comment { Line(.doc, "…") }`.

### `#if os(...)` is gen-time, not output

A `#if os(macOS) … #endif` block in the input is evaluated when the wrapped file compiles, controlling whether the enclosed DSL expressions are part of the builder. It does *not* emit a `#if os(macOS)` directive into the rendered Swift output. If you want compile-time-conditional output, emit the `#if` lines as raw text via `VariableExp("#if os(macOS)")` (or write a small helper).

## Platform notes

**macOS** is the primary target. The build and release flows live in `Scripts/`; the bundle is portable across machines with the same Swift version.

**Linux** is verified on `swift:6.0-jammy/aarch64`. One adjustment compared to macOS: the Mach-O `install_name` rewrite in `Scripts/build-skit-release.sh` is skipped — GNU `ld` doesn't accept the flag. The `-rpath` injection (which is what actually locates the dylib at runtime) works on both platforms.

The Foundation.Process workarounds described earlier are Linux-driven. `Process.waitUntilExit()` blocks indefinitely on already-exited children on `swift:6.0-jammy/aarch64` — `skit` uses `DispatchSemaphore` everywhere a child wait is needed, and drains stdout/stderr pipes concurrently to avoid deadlocks when either pipe buffer fills.

**Windows** is not supported.

## What's deferred

A few things were considered for v1 and explicitly punted:

- **Auto-rebuild on toolchain mismatch** — [#157](https://github.com/brightdigit/SyntaxKit/issues/157). Today the user gets a clear error and a rebuild command; tomorrow `skit` should rebuild `libSyntaxKit` from bundled sources transparently and cache the result per Swift version. The stamp-and-detect path shipped in this release is the foundation; the rebuild fallback is the natural next step.
- **Multi-file output from a single input** — out of scope. The folder mode handles N-inputs → N-outputs; if you need fan-out from one logical generator, split it into multiple input files.
- **Sandboxing the spawned `swift`** — out of scope. The threat model is "you ran your own code", same as `swift Input.swift` by hand.
- **HTTP / web-server form** — out of scope for the CLI. A long-lived server could share a warm interpreter and the caches across requests, but that's a different shape with its own isolation questions. Revisit later.

## Reference

- [`Sources/skit/README.md`](../Sources/skit/README.md) — per-target quick reference (flag table).
- [`Docs/skit-internals.md`](skit-internals.md) — per-module reference for Runner, OutputCache, and Toolchain.
- [`Scripts/build-skit-release.sh`](../Scripts/build-skit-release.sh) — release-bundle builder.
- [`Docs/research/tuist-manifest-pipeline.md`](research/tuist-manifest-pipeline.md) — the manifest-pipeline pattern this CLI borrows from.
- [Issue #154](https://github.com/brightdigit/SyntaxKit/issues/154) — original tracking issue.
- [Issue #157](https://github.com/brightdigit/SyntaxKit/issues/157), [Issue #158](https://github.com/brightdigit/SyntaxKit/issues/158) — follow-ups.
