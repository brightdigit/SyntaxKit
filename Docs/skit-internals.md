# `skit` internals: Runner, OutputCache, Toolchain

A contributor's map of the three modules that do the actual work inside `skit run`. For the **why** (design rationale, trade-offs, sharp edges) see [`Docs/skit.md`](skit.md). For the **what** (flags, behaviour) see [`Sources/skit/README.md`](../Sources/skit/README.md). This doc covers the **how** — what each module needs, what it produces, and how they call each other.

## The pipeline

`Skit+Run.swift` is the only caller. Per invocation it does, in order:

1. **`Bundle.main.resolveLibPath(candidates:)`** (`Sources/skit/Bundle+ResolveLibPath.swift`) — locate the lib bundle (`libSyntaxKit.dylib` + swiftmodules). The caller passes `--lib` and `$SKIT_LIB_DIR` as candidates; Bundle falls back to `<exec>/lib/` and `<exec>/../lib/skit/`.
2. **`ToolchainCheckResult(libPath:)`** (`Sources/skit/ToolchainCheckResult.swift`) — verify the bundle's recorded `swift --version` matches the local one. Refuses to spawn on mismatch.
3. **`runSingleFile(...)` or `runDirectory(...)`** — dispatch into Runner. Everything downstream (wrap, spawn, output-cache lookup/store) happens inside Runner.

**Toolchain** is consumed transitively (by `Bundle+ResolveLibPath`, `FileManager+IsLibDir`, and `OutputCache`) — it's never called directly from the CLI driver. **OutputCache** is an implementation detail of `Runner.processFile`, never called from the CLI driver either. The CLI driver only sees two surfaces: `Bundle.main.resolveLibPath` and `runSingleFile`/`runDirectory`.

## Toolchain (`Toolchain.swift` + extensions)

**Purpose.** Provide the shared utilities that describe (a) the local `swift` toolchain, (b) the bundled SyntaxKit dylib, and (c) where skit's caches live on disk. These are infrastructure, not features — they exist so the rest of the code doesn't have to re-derive them.

**Surface area** (all `internal`, all inside `#if canImport(Subprocess)`):

| Symbol | Defined in | What it returns | Consumers |
|---|---|---|---|
| `String.dylibFilename` | `String+DylibFilename.swift` | `"lib<self>.dylib"` on macOS, `"lib<self>.so"` on Linux | `FileManager.isLibDir`, `FileManager.libStamp` |
| `FileManager.libStamp(libPath:)` | `FileManager+LibStamp.swift` | `"<size>/<mtime>"` of `libSyntaxKit.{dylib,so}`, or nil | `OutputCache.key` |
| `captureSwiftVersion()` | `Toolchain.swift` | verbatim `swift --version` stdout (≤4 KiB), or nil on spawn failure | `Skit.Run.run` (called once per invocation, then threaded into `ToolchainCheckResult.init` and `OutputCache.init`) |
| `syntaxKitCacheRoot()` | `Toolchain.swift` | `~/Library/Caches/com.brightdigit.SyntaxKit` (macOS), `$XDG_CACHE_HOME/syntaxkit` or `~/.cache/syntaxkit` (Linux) | `OutputCache.init` |

**Why these four belong together.** They all answer the same question from different angles: "what state of the world does a cache key depend on?" The Swift toolchain (`captureSwiftVersion`), the runtime dylib (`libStamp` via `String.dylibFilename`), and the on-disk cache layout (`syntaxKitCacheRoot`). Together they give `OutputCache` everything it needs to compute a stable, sound key. The two that fit naturally as instance APIs (`String.dylibFilename`, `FileManager.libStamp`) live in their own extension files; the rest stay as free functions in `Toolchain.swift`.

## Runner (`Runner.swift`)

**Purpose.** Orchestrate per-input render: pick single-file vs. directory mode, wrap each input into a complete Swift program, spawn `swift` on it with a timeout watchdog, surface output, and consult the output cache.

**What it needs from the caller:**
- `libPath: String` — the lib bundle dir from step 1; reused for the `swift` invocation's link/rpath flags.
- `useCache: Bool` — gates OutputCache lookup/store (`--no-cache` sets this to false).
- `timeoutSeconds: Int` — per-input watchdog (`0` opts out; default 60s; on expiry, exit 124 matching POSIX `timeout(1)`).

**Two entry points:**

| Function | When | Failure semantics |
|---|---|---|
| `runSingleFile(inputPath:outputPath:libPath:useCache:timeoutSeconds:)` (`Runner.swift:72`) | One input, one output (or stdout) | Calls `exit()` on non-zero subprocess result — caller won't see a thrown error in that path |
| `runDirectory(inputDir:outputDir:libPath:useCache:timeoutSeconds:)` (`Runner.swift:110`) | Walks `**/*.swift` under `inputDir`, bounded concurrency = `ProcessInfo.activeProcessorCount`, mirrors output into `outputDir` | Returns 0/1 instead of `exit()` — partial failure allowed, successful peers still written, one-line summary printed to stderr |

**The per-input work** (`processFile`, `Runner.swift:267`):

1. Load source bytes.
2. If `useCache`, compute the output cache key via `outputCacheKey(inputSource:libPath:)` and try a hit.
3. On miss: `wrap` the source (hoist imports, splice body into `Group { … }`, fence with `#sourceLocation` so compiler diagnostics map back to the original file), write to a per-invocation `skit-<UUID>/` temp dir, spawn `swift`, rewrite stderr to swap the temp path for the original path, store the result via `storeCachedOutput`, return.

The temp dir is cleaned with `defer { try? removeItem }` so a failed spawn doesn't leak files.

**The spawn** (`runSwift`, `Runner.swift:417`). Fixed argument list:
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

**Shape.** Single `internal struct OutputCache: @unchecked Sendable`, built once per `skit run` invocation in `Skit.Run.run` and shared across every input. `init(swiftVersion:fileManager:processInfo:)` throws — it resolves the cache root via `Toolchain.syntaxKitCacheRoot()`, binds it to `self.root` (`<syntaxKitCacheRoot>/outputs/`), and stores `swiftVersion` so key derivation never has to re-spawn `swift`. The caller wraps the init in `try?` so a non-derivable cache root short-circuits silently (same effective behaviour as `--no-cache` for that invocation).

The `@unchecked Sendable` conformance covers the `FileManager` / `ProcessInfo` stored properties (reference types that don't auto-derive Sendable, but the singletons we use are thread-safe for these operations). Runner shares one `OutputCache?` instance across concurrent `runOne` tasks in directory mode.

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

**On-disk layout.** `<syntaxKitCacheRoot>/outputs/<key>/output.swift`. The per-key directory is derived by the private `directory(for:)` helper; the root comes from `Toolchain.syntaxKitCacheRoot()` once, at init.

**Why FNV-1a, not SHA-256.** The cache keys aren't security-critical — there's no adversary trying to forge a collision — so `ContentHasher` uses a 64-bit FNV-1a. Deterministic across processes and platforms (unlike Swift's stdlib `Hasher`, whose seed is per-process randomized), which is what makes the keys usable as on-disk directory names.

## Data-flow recap

```
Skit.Run.run()
 ├─ Bundle.main.resolveLibPath(candidates: --lib, $SKIT_LIB_DIR)   → libPath
 │    └─ FileManager.default.isLibDir → "SyntaxKit".dylibFilename
 ├─ captureSwiftVersion()                                          → swiftVersion (spawned exactly once)
 ├─ ToolchainCheckResult(libPath:, swiftVersion:)                  → gate (compare to bundle stamp)
 ├─ try? OutputCache(swiftVersion:)                                → cache (nil under --no-cache or unresolvable root)
 └─ runSingleFile / runDirectory(libPath, cache, timeoutSeconds)
      └─ processFile(input)
           ├─ cache?.key(forInput: source, libPath:)                ← self.swiftVersion + FileManager.default.libStamp
           ├─ cache.lookup(key:)                                    ← hit returns immediately
           ├─ wrap(source) → temp wrapper.swift
           ├─ runSwift(wrappedPath, libPath)                        ← spawns `swift` linked against libSyntaxKit
           └─ try? cache.store(key:, data:)                         ← on the way out (atomic stage+rename)
```

Three coupling facts worth remembering:

- **Toolchain is shared infrastructure.** `OutputCache` depends on three of its four utilities; the bundle-resolution code depends on `dylibFilename`. None of those callers know or care that the utilities live in `Toolchain.swift` — they just call free functions.
- **Runner is the only place OutputCache is touched.** If you ever want a non-CLI consumer of skit (e.g. a long-running server), you'd either call `processFile` directly or replicate its cache logic. Don't instantiate `OutputCache` from elsewhere.
- **Cache safety under concurrency.** Both the store path (in `OutputCache`) and the bundle-resolution path are designed to be safe under concurrent invocations: write into `tmp.<pid>.<uuid>/`, then `moveItem` to install. Race-loser swallows the rename error if the destination is now populated by a peer.
