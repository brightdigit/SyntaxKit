# Design sketch: a CLI for SyntaxKit-driven codegen

> Phase 2 deliverable for [issue #154](https://github.com/brightdigit/SyntaxKit/issues/154). Builds on [`tuist-manifest-pipeline.md`](./tuist-manifest-pipeline.md). Nothing here is implemented — this is the design we'd validate with the POC in §6.

## 1. What we're borrowing from Tuist — and what we're not

From Phase 1, Tuist's manifest pipeline reduces to four moving parts:

1. A **public DSL framework** that ships next to the CLI binary (`ProjectDescription.framework`).
2. A **script runner** that invokes `xcrun swift <Project.swift>` with `-I/-L/-F` pointing at that framework, captures stdout, and slices out a token-delimited payload.
3. A **helpers compiler** that pre-builds `Tuist/ProjectDescriptionHelpers/*.swift` into a sibling dylib so manifests can `import ProjectDescriptionHelpers`.
4. A **two-tier cache** (helpers module + decoded manifest) keyed on source hashes + toolchain/tool versions.

We borrow (1), (2), (3), and (4). We **don't** borrow Tuist's "manifest" framing — no `Project.swift`-style wrapper, no `Output(...)` value, no token-delimited stdout payload. Tuist needs the wrapper because its host has to re-interpret the description into an `xcodeproj`. SyntaxKit doesn't: the input file is *pure DSL* — a series of `CodeBlock` expressions — and the CLI generates the boilerplate that turns it into a runnable Swift program.

## 2. CLI shape

The CLI is `stdin → stdout`-shaped, with a SyntaxKit-aware `swift` invocation as the engine:

```
syntaxkit run Input.swift                # rendered Swift source to stdout
syntaxkit run Input.swift -o Output.swift  # write to a file (atomic)
syntaxkit run InputDir/ -o OutputDir/      # walk InputDir/*.swift, mirror paths into OutputDir/
```

**Input file:** pure DSL. A series of `CodeBlock` expressions, optionally preceded by `import` declarations. No `print`, no `@main`, no boilerplate. Example:

```swift
// Person.swift
import SyntaxKit   // optional — only needed for IDE / autocomplete

Struct("Person") {
    Variable(.let, name: "name", type: "String")
    Variable(.let, name: "age", type: "Int")
}
```

That's the entire file. Top-level expressions form an implicit `@CodeBlockBuilder` body that the CLI wraps for execution — see §3.

**Output:** the rendered Swift source produced by `generateCode()`. The CLI does not reshape it.

**Stderr:** forwarded to the user's terminal. The captured output is stdout-only. (The wrapper writes to stdout via a single `print`; if helpers or the user's DSL want to log debug info, they should use `FileHandle.standardError.write(...)`.)

**Folder mode:** when the input is a directory, the CLI walks `**/*.swift` and produces a parallel tree of outputs (one input file → one output file, mirrored relative path). Files starting with `_` are skipped (convention for shared helpers — see §4).

**Exit codes:** child `swift` non-zero → CLI non-zero with stderr preserved. No retries.

## 3. Process model: wrap, then spawn

Because the input is pure DSL rather than a runnable Swift program, the CLI does a tiny **wrap** step before spawning `swift`.

**Wrap.** Read the input file. Use SwiftSyntax (already a dep — `Docs/SwiftSyntax-LLM.md`) to split the top of the file into (a) any leading `import` declarations and (b) the remaining body. Generate a temporary `Input.wrapped.swift`:

```swift
import SyntaxKit
<hoisted imports from input>

let __syntaxkit_root = Group {
<body of input, verbatim, indented>
}
print(__syntaxkit_root.generateCode())
```

`Group` (`Sources/SyntaxKit/Utilities/Group.swift`) already uses `@CodeBlockBuilder`, so its closure body accepts a series of `CodeBlock` expressions exactly the way the user wrote them. `import SyntaxKit` is always injected; duplicates from the input are harmless.

**Spawn.** Adopt Tuist's model `(b)` from Phase 1 §2 — `swift` in script mode against the wrapped file, pipe through:

```
/usr/bin/env swift \
  -suppress-warnings \
  -I  <SyntaxKitSearchPaths.include> \
  -L  <SyntaxKitSearchPaths.library> \
  -F  <SyntaxKitSearchPaths.framework> \
  -lSyntaxKit -framework SyntaxKit \
  -Xcc -I -Xcc <SyntaxKitSearchPaths.cShimsInclude> \
  -Xlinker -rpath -Xlinker <SyntaxKitSearchPaths.library> \
  -I … -L … -F … -l<CodegenHelpers>          # optional, when helpers exist
  <tmp>/Input.wrapped.swift
```

The `-Xcc -I -Xcc <…>` flag is non-obvious but required (POC step 1 finding): SyntaxKit transitively depends on `_SwiftSyntaxCShims` whose module map lives in `swift-syntax/Sources/_SwiftSyntaxCShims/include/`. The bundled-binary release must ship this header directory alongside the dylib and the SwiftSyntax `.swiftmodule` files. Without the flag, the script compile fails with `missing required module '_SwiftSyntaxCShims'`. The `-Xlinker -rpath -Xlinker <…>` flag tells the just-built script's dylib loader where to find `libSyntaxKit.dylib` at runtime.

No `--syntaxkit-dump` flag, no start/end tokens. The child's stdout is the rendered Swift source verbatim. The CLI's job is wrap → `Process` → capture stdout → atomic write to destination → clean up temp wrapper.

Use `/usr/bin/env swift` rather than `/usr/bin/xcrun swift` so the same code path runs on Linux. `xcrun` is mac-only and is implicit when `env swift` resolves to Xcode's swift on macOS.

**Why wrap instead of requiring `print()` in the input.** Two reasons. First, the user's authoring surface is *just* DSL — declarative, no I/O verbs. Second, error reporting: when the child `swift` reports a diagnostic at `Input.wrapped.swift:42`, the CLI can map that line back to the original `Input.swift` (the wrapper is line-faithful aside from a known prefix offset) and rewrite the path in stderr before forwarding.

## 4. Helpers

Same mechanism as Tuist (Phase 1 §4), folder name TBD — `Helpers/` adjacent to the input file or input directory is the obvious choice. The CLI walks up from the input path looking for a `Helpers/` directory, globs `**/*.swift` (excluding files prefixed with `_` to allow private helpers within helpers), and pre-compiles them into `lib<HelpersName>.dylib` via:

```
swiftc -module-name SyntaxKitHelpers \
       -emit-module -emit-module-path <out>/SyntaxKitHelpers.swiftmodule \
       -parse-as-library -emit-library \
       -suppress-warnings \
       -I … -L … -F … -lSyntaxKit -framework SyntaxKit \
       Helpers/**/*.swift
```

The output dylib is then added to the input script's invocation via `-I/-L/-F/-l`. Scripts can `import SyntaxKitHelpers` and use shared codegen utilities.

Compile into a `tmp.<pid>.<uuid>` staging directory and atomic-rename into the cache path, mirroring `ProjectDescriptionHelpersBuilder.swift:204-244` — concurrent CLI invocations need to be safe.

## 5. Caching

Two layers, both mirroring Tuist (Phase 1 §5).

**Helpers cache.** Keyed by:

| Field | Source |
| --- | --- |
| per-file SHA-256s | `Helpers/**/*.swift`, sorted |
| `syntaxkitVersion` | bundled SyntaxKit dylib version |
| `swiftlangVersion` | `swift --version` |
| `osVersion` | `uname -r` (macOS or Linux) |
| `cacheSchemaVersion` | bumped on layout changes |

Hash → directory name → reuse if present.

**Output cache.** Skip the swift spawn entirely when nothing has changed. Keyed by:

| Field | Source |
| --- | --- |
| `inputHash` | SHA-256 of the input `.swift` file |
| `helpersHash` | the helpers cache key above, or empty |
| `syntaxkitVersion` | bundled SyntaxKit dylib version |
| `swiftlangVersion` | `swift --version` |
| `envHash` | md5 of `SYNTAXKIT_*` env vars |
| `cacheSchemaVersion` | bumped on layout changes |

On hit, copy the cached rendered output directly to the destination — no `swift` spawn. On miss, run and re-cache.

Cache location: `~/.cache/syntaxkit/` on Linux, `~/Library/Caches/com.brightdigit.SyntaxKit/` on macOS (XDG-aware via `XDG_CACHE_HOME`).

## 6. Smallest possible proof-of-concept steps

Each step is independently shippable and de-risks the next.

1. **Hand-driven wrap + spawn.** Hand-write a pure-DSL `Input.swift` and a hand-rolled `Input.wrapped.swift` that imports SyntaxKit, splices the body into `Group { … }`, and prints `generateCode()`. Invoke it manually with `swift Input.wrapped.swift -I … -L … -F … -lSyntaxKit -framework SyntaxKit` against a local `swift build` of SyntaxKit. **Goal: prove the `swift`-script + framework-search-path mechanism works for SyntaxKit at all, that a result-builder closure spliced from user text compiles cleanly, and measure cold-start cost.** Cold-start is the single biggest risk to retire — if it's 20+ seconds, the design needs rethinking.
2. **CLI subcommand for single-file mode.** Add `syntaxkit run <input.swift>`: parse out top-level imports with SwiftSyntax, write `Input.wrapped.swift` to a temp dir, spawn `swift` via `Foundation.Process`, capture stdout, write to `-o <output.swift>` (or stdout if no `-o`). Stderr is forwarded; rewrite `Input.wrapped.swift:LINE` references back to `Input.swift:LINE` before forwarding.
3. **Folder mode.** Walk `InputDir/**/*.swift`, mirror paths into `OutputDir/`. Add `_`-prefix skip rule. Parallelize cautiously (`swift` spawns aren't free — gate on a small concurrency limit, maybe `ProcessInfo.activeProcessorCount`).
4. **Ship a bundled-binary release.** Build SyntaxKit as a `type: .dynamic` library under `-c release`, then `strip -x` the resulting dylib. Bundle the stripped `libSyntaxKit.dylib` + every `.swiftmodule` SyntaxKit publicly re-exports (SwiftSyntax + version-suffixed variants, SwiftOperators, SwiftParser) + the `_SwiftSyntaxCShims/include/` header dir in a `lib/` directory next to the CLI binary. Write a `ResourceLocator` analog (mirrors `cli/Sources/TuistLoader/Utils/ResourceLocator.swift:52-83`). POC step 1 confirmed cold-start with this layout is ~720ms; stripped release dylib is **9.3 MB** on Apple Silicon (down from 25 MB debug / 18 MB unstripped release).
5. **Helpers directory.** Discovery + compile + flag-splicing.
6. **Output cache.** Add the cache, keyed as in §5. Add `--no-cache` for debugging.
7. **Linux smoke test.** Confirm `/usr/bin/env swift` works on Linux with the bundled dylib layout (no framework search path, but `-I + -L + -lSyntaxKit` should be sufficient, matching Tuist's `ProjectDescriptionSearchPaths.Style.commandLine` branch).

## 7. What we still need to verify

- **Cold-start cost.** ~~Single biggest unknown.~~ Answered by POC step 1: ~720ms cold, ~110ms warm. See [`poc-step1-results.md`](./poc-step1-results.md).
- **SyntaxKit `if`-in-`Group` compiler crash.** POC step 1 surfaced this: `CodeBlockBuilderResult` claims `buildEither`/`buildOptional` support but conditionals trigger a type-checker failure-to-diagnose. Independent of the CLI design but blocks users writing conditional codegen. File as a separate SyntaxKit bug.
- **Splice fidelity.** When the input body lives inside a `Group { … }` closure, is everything users naturally write in the DSL still legal? Result-builder closures don't allow `import`, top-level type decls, or top-level `let`/`var` outside the builder DSL. The wrapper hoists `import`s; we need to confirm there's no other top-level construct users would reasonably write that the wrap step would break. Verify in step 1 with a few realistic inputs (large struct, nested types, conditionals via `if`-in-builder).
- **`Process` stdout/stderr separation.** Tuist captures stdout-only and merges stderr via `CommandError`. Foundation's `Process` has the same split — confirm it doesn't interleave under load, and confirm the CLI doesn't accidentally swallow stderr.
- **`swift` script-mode quirks.** `swift <file.swift>` runs in interpret/`-frontend -interpret` mode. Some features (`@main`, certain attributes) behave differently than in compile mode. Top-level `print` statements are fine. Verify in step 1.
- **SwiftSyntax linkage stability across toolchains.** SwiftSyntax pins to specific Swift toolchain versions. The bundled dylib is built against a particular toolchain; if the user's `swift` is from a newer or older release, ABI breakage is possible. Mitigation: cache key includes `swiftlangVersion`, plus a clear error when the gap is too wide.
- **What if a single input script needs to produce multiple files?** Out of scope for v1. Split into multiple inputs and use folder mode. If demand materializes, we can layer in a `--multi` envelope mode (a script writes a small JSON manifest to stdout, CLI fans out to multiple files) without breaking single-file semantics.
- **Sandboxing.** Out of scope for v1. Input scripts are user-owned code in their own repo — running them has the same threat model as running `swift Input.swift` by hand. Revisit if/when this CLI runs untrusted scripts (CI for OSS contributions, etc.).
- **Timeout.** Add one. Tuist's omission (Phase 1 §7) is a bug, not a feature. 60s default `Process` wait with `SIGTERM` → 5s grace → `SIGKILL`. Override via `--timeout <seconds>`.
- **Web-server form.** Out of scope for the CLI POC, but on the table as a follow-up once the 7-step ladder is done. A long-lived server could reuse a warm `swift` interpreter across requests and share the helpers + output caches across tenants — both of which the CLI gives up on every invocation. Open design questions: request shape (raw DSL POST vs. structured), whether helpers are uploaded per-request or baked into the server image, and isolation between requests (the CLI's "run user code in your own repo" threat model doesn't transfer). Revisit after step 7.
