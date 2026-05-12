# POC Step 5 — Results

> Companion to [`codegen-cli-design.md`](./codegen-cli-design.md) §4 + §6 step 5. Goal: let inputs `import SyntaxKitHelpers` from a `Helpers/` directory adjacent to the input, with discovery + on-demand `swiftc` compile + a per-toolchain cache.

## What landed

1. **`Sources/skitrun/Helpers.swift`.** New module with three responsibilities:
   - `discoverHelpersDir(near:)` walks up from the input path looking for a `Helpers/` directory. Single-file mode starts from the file's parent; folder mode starts from the input directory. Walk-up stops at the filesystem root.
   - `collectHelperSources(in:)` globs `**/*.swift` under the helpers dir, skipping `_`-prefixed files (same convention as input enumeration).
   - `buildHelpers(helpersDir:libPath:)` hashes the sources + Swift version + dylib stamp into a cache key under `~/Library/Caches/com.brightdigit.SyntaxKit/helpers/<hash>/`. On a cache miss, it shells out to `swiftc` into a `tmp.<pid>.<uuid>/` staging dir, then atomic-renames into the cache path (`ProjectDescriptionHelpersBuilder` pattern from Tuist).

2. **`Sources/skitrun/Main.swift` wiring.**
   - `CLIArgs` gains `--helpers <dir>` (explicit override) and `--no-helpers` (skip discovery). Default is auto.
   - `runSwift` splices `-I/-L/-lSyntaxKitHelpers -Xlinker -rpath -Xlinker <cache-dir>` when helpers are present.
   - Folder mode's `collectInputs` now also yields directories so it can call `enumerator.skipDescendants()` when it hits a `Helpers/` directly under the input root — otherwise the helpers would be re-processed as inputs.
   - Helpers compile happens **once per invocation** in folder mode (not per input file).

3. **`Docs/research/poc-step5.sh`.** Standalone demo: builds skitrun, stages a runtime lib, writes a tiny `Helpers/Models.swift` exporting `equatableModel(_:fields:)`, and two `inputs/*.swift` files that `import SyntaxKitHelpers` and call the helper.

## Verified flows

| Flow | Result |
| --- | --- |
| Cold run (cache cleared, helpers compile from scratch) | ✓ 2.96s real |
| Warm run (cache hit, same helper sources) | ✓ 0.54s real |
| Folder mode against `demo/` containing `Helpers/` + `inputs/` | ✓ 2/2 succeeded, `Helpers/*.swift` not enumerated as input |
| `--no-helpers` with an input that imports `SyntaxKitHelpers` | ✓ child `swift` errors with `no such module 'SyntaxKitHelpers'`, exit non-zero |

The cached layout for a single helper file:

```
~/Library/Caches/com.brightdigit.SyntaxKit/helpers/<sha256>/
  libSyntaxKitHelpers.dylib
  SyntaxKitHelpers.swiftmodule
  SyntaxKitHelpers.swiftdoc
  SyntaxKitHelpers.abi.json
  SyntaxKitHelpers.swiftsourceinfo
```

## Cache key

SHA-256 over (in order):
- Cache schema version string (`v1`).
- For each helper source (sorted by absolute path): `lastPathComponent` + file bytes.
- `swift --version` output.
- `libSyntaxKit.dylib` size and modification time (proxy for SyntaxKit version until the bundle is versioned).

Mutating any helper source, switching toolchains, or rebuilding SyntaxKit invalidates the cache. Adding a `cacheSchemaVersion` bump constant covers future layout changes.

## Known rough edges

- **Helpers cold compile is the dominant cost.** 2.96s vs 0.54s warm — the helper compile is ~2.5s on top of the ~0.5s `swift` interpret cost. Once cached it's free, but the first run after a clean checkout is noticeably slow. Acceptable for v1; could be sped up by caching the helpers `.o` files separately, but that's a step-6+ optimization.
- **Walk-up false positives.** If a user happens to have an unrelated `Helpers/` somewhere up-tree (e.g. a sibling library), skitrun will try to compile it. `--helpers <dir>` or `--no-helpers` is the escape hatch. A future heuristic could require a sentinel file (`Helpers/.syntaxkit-helpers`) before claiming the directory.
- **Import-line diagnostics off by one.** When the user's input has `import Foo` on line 1, the wrap step puts an injected `import SyntaxKit` above it, so a child-compile error on the user's import reports `:2:8` instead of `:1:8`. `#sourceLocation` directives only wrap the body, not the hoisted imports. Easy follow-up: emit a `#sourceLocation` directive per hoisted import too.

## What's next

Step 6: **output cache.** Today every `skitrun` invocation re-spawns `swift` to render the input, even when nothing has changed. Add the per-input output cache from [`codegen-cli-design.md` §5](./codegen-cli-design.md#5-caching), keyed by input hash + helpers-cache key + Swift version + envHash. On a hit, skip the spawn entirely and copy the rendered output to the destination. Add `--no-cache` for debugging.
