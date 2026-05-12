# POC Step 6 — Results

> Companion to [`codegen-cli-design.md`](./codegen-cli-design.md) §5 + §6 step 6. Goal: skip the `swift` spawn entirely when the rendered output for an input is already cached, with a key that captures everything that could change the output.

## What landed

1. **`Sources/skitrun/OutputCache.swift`.** Three functions:
   - `outputCacheKey(inputSource:helpers:libPath:)` — SHA-256 over cache schema version + input bytes + helpers cache key (or `"no-helpers"`) + `swift --version` + libSyntaxKit dylib stamp + sorted `SKITRUN_*` / `SYNTAXKIT_*` env vars.
   - `lookupCachedOutput(key:)` — returns the cached `output.swift` bytes from `~/Library/Caches/com.brightdigit.SyntaxKit/outputs/<key>/output.swift`, or `nil` on miss.
   - `storeCachedOutput(key:data:)` — atomic write via `tmp.<pid>.<uuid>/` staging dir + rename. Concurrent writers race safely; the loser drops their copy if the destination already exists.

2. **`Sources/skitrun/Main.swift` wiring.**
   - `processFile` reads the input source, computes the cache key, and short-circuits on hit — no temp wrapper, no `swift` spawn, just return the cached bytes with `exitCode = 0`.
   - On miss, the normal wrap + spawn path runs; if `swift` returns 0, the rendered output is stored under the key.
   - Only successful (exit 0) runs are cached. Failed runs always re-spawn so the user sees fresh diagnostics.
   - `CLIArgs` gains `--no-cache` to skip the cache entirely (still useful when chasing flaky output or after manually deleting the cache).
   - The flag threads through `runSingleFile` and `runDirectory` so folder mode can opt out wholesale.

3. **Helpers.swift internal exposure.** `syntaxKitCacheRoot`, `captureSwiftVersion`, and `libStamp` were `private`; they're now `internal` so OutputCache can reuse them rather than duplicating.

## Verified flows

From `Docs/research/poc-step6.sh` (single input, no helpers):

| Run | Real time | Notes |
| --- | ---: | --- |
| Cold (cache cleared) | 0.55s | swift spawn + compile + store |
| Warm (cache hit) | 0.14s | FS read only, no swift spawn |
| `--no-cache` | 0.27s | always spawn, ignore cache |
| After mutation (miss) | 0.41s | new key, recompile, store |
| Warm after mutation | 0.14s | second key cached |

After mutation, the cache directory contains **two** entries (one per input version) — old keys aren't evicted, which is fine for a per-toolchain cache where stale entries are dead weight, not correctness risks. Eviction can be a follow-up if cache size becomes a complaint.

## Cache key, written out

```
SHA-256(
  "v1"                                         // cache schema version
  + input.swift bytes                          // verbatim user input
  + helpersCacheKey || "no-helpers"            // helpers fingerprint (sibling cache)
  + swift --version stdout                     // toolchain fingerprint
  + "<size>/<mtime>" of libSyntaxKit.dylib     // SyntaxKit fingerprint proxy
  + sorted SKITRUN_*/SYNTAXKIT_* env (k=v\0)   // env override sensitivity
)
```

Two cooperating cache layers — helpers (step 5) and outputs (step 6) — sit side-by-side under `~/Library/Caches/com.brightdigit.SyntaxKit/{helpers,outputs}/<sha>/`. Helpers cache hits are reused across many inputs; output cache hits are per-input.

## Known rough edges

- **Output cache stores stdout only.** Stderr from a successful run (e.g. warnings even with `-suppress-warnings` off) is discarded on a hit. With `-suppress-warnings` in `runSwift` this is rarely visible, but it does mean cache hits suppress warnings that would have appeared on a fresh run. Acceptable for a generator; revisit if SyntaxKit grows runtime-side warnings.
- **`libStamp` is a coarse proxy.** Size + mtime catches normal rebuilds but a deterministic rebuild that preserves both would slip past. Hashing the dylib is correct but slow (9.3 MB per invocation defeats the cache). The right long-term fix is embedding a SyntaxKit version constant the bundle exports.
- **No size cap or eviction.** A repo that touches inputs frequently will accrete cache entries. Each is small (a few hundred bytes of rendered Swift) so the practical ceiling is high, but a `--prune` subcommand is a reasonable v1.1 addition.

## What's next

Step 7: **Linux smoke test.** Confirm `/usr/bin/env swift` + the bundled-dylib layout works on Linux without `-F` framework search paths — `-I + -L + -lSyntaxKit` should be sufficient per Tuist's `ProjectDescriptionSearchPaths.Style.commandLine` branch. CryptoKit is macOS-only; Linux will need `swift-crypto` or a small fallback hash impl behind a `#if canImport(CryptoKit)` shim. After that, the 7-step ladder is complete.
