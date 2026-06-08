# `skit` internals: Runner, OutputCache, toolchain utilities

A contributor's map of the modules that do the actual work inside `skit run`. For the **why** (design rationale, trade-offs, sharp edges) see [`Docs/skit.md`](skit.md). For the **what** (flags, behaviour) see [`Sources/skit/README.md`](../Sources/skit/README.md). This doc covers the **how** — what each module needs, what it produces, and how they call each other.

## The pipeline

`Skit+Run.swift` is the only caller. Per invocation it does, in order:

1. **`Bundle.main.resolveLibPath(candidates:)`** (`Sources/skit/Bundle+ResolveLibPath.swift`) — locate the lib bundle (`libSyntaxKit.dylib` + swiftmodules). The caller passes `--lib` and `$SKIT_LIB_DIR` as candidates; Bundle falls back to `<exec>/lib/` and `<exec>/../lib/skit/`.
2. **`ToolchainCheckResult(libPath:)`** (`Sources/skit/ToolchainCheckResult.swift`) — verify the bundle's recorded `swift --version` matches the local one. Refuses to spawn on mismatch.
3. **`Runner(libPath:cache:timeoutSeconds:)`** then **`runner(input:output:)`** — bind the per-invocation configuration into a `Runner` value and call it (via `callAsFunction`) with the raw input/output paths. The runner classifies single-file vs. directory mode and everything downstream (wrap, spawn, output-cache lookup/store) happens inside `Runner`.

The **toolchain utilities** are consumed transitively (by `Bundle+ResolveLibPath`, `FileManager+IsLibDir`, and `OutputCache`) — they're never called directly from the CLI driver. **OutputCache** is an implementation detail of `Runner.processFile`, never called from the CLI driver either. The CLI driver only sees two surfaces: `Bundle.main.resolveLibPath` and calling the `Runner` value itself (`runner(input:output:)`).

## Toolchain utilities (no single file)

**Purpose.** Provide the shared utilities that describe (a) the local `swift` toolchain, (b) the bundled SyntaxKit dylib, and (c) where skit's caches live on disk. These are infrastructure, not features — they exist so the rest of the code doesn't have to re-derive them. There is no longer a `Toolchain.swift`: each utility was lifted onto the type it naturally belongs to (no file-scope globals, per the project convention).

**Surface area** (all inside `#if canImport(Subprocess)`):

| Symbol | Defined in | What it returns | Consumers |
|---|---|---|---|
| `String.dylibFilename` | `String+DylibFilename.swift` | `"lib<self>.dylib"` on macOS, `"lib<self>.so"` on Linux | `FileManager.isLibDir`, `FileManager.libStamp` |
| `FileManager.libStamp(libPath:)` | `FileManager+LibStamp.swift` | `"<size>/<mtime>"` of `libSyntaxKit.{dylib,so}`, or nil | `OutputCache.key` |
| `Skit.Run.captureSwiftVersion()` | `Skit+Run.swift` (`fileprivate`) | verbatim `swift --version` stdout (≤4 KiB), or nil on spawn failure | `Skit.Run.run` (called once per invocation, then threaded into `ToolchainCheckResult.init` and `OutputCache.init`) |
| `ProcessInfo.syntaxKitCacheRoot(default:)` | `ProcessInfo+SyntaxKitCacheRoot.swift` | `$XDG_CACHE_HOME/syntaxkit` when that env var is set, else the passed-in `default` | `OutputCache.init` |

`OutputCache` supplies that `default` via its own `private static let defaultCacheRoot` — `~/Library/Caches/com.brightdigit.SyntaxKit` (macOS) or `~/.cache/syntaxkit` (Linux), computed once since the home dir is fixed for the process lifetime.

**Why these belong together.** They all answer the same question from different angles: "what state of the world does a cache key depend on?" The Swift toolchain (`captureSwiftVersion`), the runtime dylib (`libStamp` via `String.dylibFilename`), and the on-disk cache layout (`syntaxKitCacheRoot`). Together they give `OutputCache` everything it needs to compute a stable, sound key. Each now lives as a method/extension on the type that owns its data: the dylib helpers on `String`/`FileManager`, the cache-root resolver on `ProcessInfo`, and the `swift --version` spawn on `Skit.Run` (its sole caller).

## Runner (`Runner.swift`)

**Purpose.** Orchestrate per-input render: pick single-file vs. directory mode, wrap each input into a complete Swift program, spawn `swift` on it with a timeout watchdog, surface output, and consult the output cache.

**Shape.** `internal struct Runner: Sendable`, constructed once per invocation in `Skit.Run.run` and (being `Sendable`) shared across the concurrent `runOne` tasks in directory mode. It holds the per-invocation configuration as stored properties, so the individual inputs don't re-thread it:
- `libPath: String` — the lib bundle dir from step 1; reused for the `swift` invocation's link/rpath flags.
- `cache: OutputCache?` — the shared output cache, or nil under `--no-cache`; gates lookup/store.
- `timeoutSeconds: Int` — per-input watchdog (`0` opts out; default 60s; on expiry, exit 124 matching POSIX `timeout(1)`).

**Single entry point.** `Runner` is callable: `callAsFunction(input:output:)` is the only `internal` method (besides `init`), so `Skit.Run.run` constructs a `Runner` and invokes it directly — `try await runner(input:, output:)` — with the raw `--input`/`-o` strings. It resolves the input via `RunInput.resolve(input:output:)` (`RunInput.swift`) — a two-case enum (`.singleFile` / `.directory`) that stats the path and enforces existence + the directory `-o` requirement, throwing `ValidationError` otherwise — then dispatches to one of two **private** mode methods:

| Method (private) | When | Failure semantics |
|---|---|---|
| `runSingleFile(inputPath:outputPath:)` | One input, one output (or stdout) | Calls `exit()` on non-zero subprocess result — caller won't see a thrown error in that path |
| `runDirectory(inputDir:outputDir:)` | Walks `**/*.swift` under `inputDir`, bounded concurrency = `ProcessInfo.activeProcessorCount`, mirrors output into `outputDir` | Returns 0/1, which `run` re-throws as `ExitCode` — partial failure allowed, successful peers still written, one-line summary printed to stderr |

**The per-input work** (`processFile(inputPath:)`, a `private` instance method):

1. Load source bytes.
2. If `cache` is non-nil, compute the output cache key via `cache.key(forInput:libPath:)` and try a hit.
3. On miss: `wrap` the source (hoist imports, splice body into `Group { … }`, fence with `#sourceLocation` so compiler diagnostics map back to the original file), write to a per-invocation `skit-<UUID>/` temp dir, spawn `swift`, rewrite stderr to swap the temp path for the original path, store the result via `cache.store(key:data:)`, return.

The temp dir is cleaned with `defer { try? removeItem }` so a failed spawn doesn't leak files. `wrap`, `collectInputs`, and `exitCode` are pure `private static` helpers (no dependency on the stored configuration).

**The spawn** (`runSwift(wrappedPath:)`). Fixed argument list:
```
swift -suppress-warnings
      -I <libPath> -L <libPath> -lSyntaxKit
      -Xcc -I -Xcc <libPath>/_SwiftSyntaxCShims-include
      -Xlinker -rpath -Xlinker <libPath>
      <wrappedPath>
```
Raced against a sleep watchdog in a throwing task group; the loser is cancelled. `timeoutSeconds <= 0` skips the race entirely.

**Output bounds.** `stdoutLimitBytes = 16 MiB`, `stderrLimitBytes = 1 MiB`. Above either limit, `Subprocess` raises a clear error rather than silently truncating. Timeout exit code is 124 (`timeoutExitCode`), matching POSIX `timeout(1)`.

## OutputCache (`OutputCache.swift`)

**Purpose.** Cache the rendered Swift (the stdout of the spawned `swift` for a given input) so re-running with unchanged inputs avoids the spawn entirely. Hit cost ≈ 0.14s on macOS vs. ~0.5s for a cold script-mode `swift` spawn.

**Shape.** Single `internal struct OutputCache: Sendable`, built once per `skit run` invocation in `Skit.Run.run` and shared across every input. `init(swiftVersion:fileManager:processInfo:)` is non-throwing — it resolves the cache root via `processInfo.syntaxKitCacheRoot(default: Self.defaultCacheRoot)`, binds it to `self.root` (`<cache-root>/outputs/`), and stores `swiftVersion` so key derivation never has to re-spawn `swift`. The caller constructs it directly (`noCache ? nil : OutputCache(swiftVersion:)`); `--no-cache` is the only path that yields a nil cache.

Sendability: the `FileManager` is injected as a `@Sendable () -> FileManager` closure (default `.default`) rather than stored directly, so the struct derives `Sendable` without an `@unchecked` escape hatch. Runner shares one `OutputCache?` instance across concurrent `runOne` tasks in directory mode.

**Surface** (all `internal` instance methods):

- **`key(forInput:libPath:)`** — synchronous (no `await`), mixes:
  - schema version (`Self.schemaVersion = "v1"` — bump to invalidate everything)
  - input source bytes (the primary driver)
  - `self.swiftVersion` (captured at init from `Skit.Run.run`)
  - libSyntaxKit `<size>/<mtime>` stamp (via `FileManager.libStamp(libPath:)`)
  - sorted, NUL-terminated `SKIT_*` / `SYNTAXKIT_*` env vars
- **`lookup(key:)`** — returns the cached `output.swift` bytes or nil.
- **`store(key:data:)`** — atomic stage+rename: writes into `tmp.<pid>.<uuid>/output.swift` next to the key dir, then `moveItem` to install. If a concurrent peer beat us to it, swallow the rename error and drop our staging copy; re-throw only if the destination is still missing afterwards.

Storage is wrapped in `try?` at the caller in `processFile` — a cache *write* failure is never a render failure; the next run just re-spawns.

**On-disk layout.** `<cache-root>/outputs/<key>/output.swift`. The per-key directory is derived by the private `directory(for:)` helper; the root comes from `processInfo.syntaxKitCacheRoot(default:)` once, at init.

**Why FNV-1a, not SHA-256.** The cache keys aren't security-critical — there's no adversary trying to forge a collision — so `ContentHasher` uses a 64-bit FNV-1a. Deterministic across processes and platforms (unlike Swift's stdlib `Hasher`, whose seed is per-process randomized), which is what makes the keys usable as on-disk directory names.

## Data-flow recap

```
Skit.Run.run()
 ├─ Bundle.main.resolveLibPath(candidates: --lib, $SKIT_LIB_DIR)   → libPath
 │    └─ FileManager.default.isLibDir → "SyntaxKit".dylibFilename
 ├─ self.captureSwiftVersion()                                     → swiftVersion (spawned exactly once)
 ├─ ToolchainCheckResult(libPath:, swiftVersion:)                  → gate (compare to bundle stamp)
 ├─ OutputCache(swiftVersion:)                                     → cache (nil only under --no-cache)
 ├─ Runner(libPath:, cache:, timeoutSeconds:)                      → runner (holds the config)
 └─ runner(input:, output:)                                       → callAsFunction → RunInput.resolve → single-file / directory
      └─ processFile(inputPath:)
           ├─ cache?.key(forInput: source, libPath:)                ← self.swiftVersion + FileManager.default.libStamp
           ├─ cache.lookup(key:)                                    ← hit returns immediately
           ├─ Self.wrap(source) → temp wrapper.swift
           ├─ runSwift(wrappedPath:)                                ← spawns `swift` linked against libSyntaxKit
           └─ try? cache.store(key:, data:)                         ← on the way out (atomic stage+rename)
```

Three coupling facts worth remembering:

- **The toolchain utilities are shared infrastructure.** `OutputCache` depends on three of the four; the bundle-resolution code depends on `dylibFilename`. They no longer share a `Toolchain.swift` — each lives as a method/extension on the type that owns its data, called like any other instance API.
- **Runner is the only place OutputCache is touched.** If you ever want a non-CLI consumer of skit (e.g. a long-running server), you'd construct a `Runner` and call its entry points (or replicate its cache logic). Don't instantiate `OutputCache` from elsewhere.
- **Cache safety under concurrency.** Both the store path (in `OutputCache`) and the bundle-resolution path are designed to be safe under concurrent invocations: write into `tmp.<pid>.<uuid>/`, then `moveItem` to install. Race-loser swallows the rename error if the destination is now populated by a peer.
