# POC Step 7 — Results

> Companion to [`codegen-cli-design.md`](./codegen-cli-design.md) §6 step 7. Goal: confirm the `skitrun` flow that worked on macOS (steps 1-6) also works on Linux with the bundled-dylib layout, no framework search paths, and no Apple-only crypto.

## What landed

1. **`swift-crypto` swap-in.** `Sources/skitrun/Helpers.swift` and `OutputCache.swift` now `import Crypto` instead of `CryptoKit`. The Apple `swift-crypto` package vends the same `SHA256` API on every platform and re-exports CryptoKit on Apple platforms when available, so there's no `#if` shim needed in skitrun's own code. Added as a Package dependency at `from: "3.0.0"`.

2. **Platform-aware dylib filename.** A new `dylibFilename(forLibrary:)` helper returns `libX.dylib` on Apple / `libX.so` on Linux. All call sites that hard-coded `libSyntaxKit.dylib` or `libSyntaxKitHelpers.dylib` now go through it: `isLibDir`, `libStamp`, helpers cache-hit check, and the `swiftc -emit-library -o` path.

3. **Skip `@rpath` install-name on Linux.** `compileHelpers` previously passed `-Xlinker -install_name -Xlinker @rpath/libSyntaxKitHelpers.dylib`. That flag is Mach-O specific; on Linux it errors at link time. Wrapped in `#if !os(Linux)`. The `-Xlinker -rpath` flag still works on both platforms and is what actually locates the dylib at runtime.

4. **`Docs/research/poc-step7.sh`.** Self-rerunning Docker wrapper: when invoked on the host it re-execs itself inside `swift:6.0-jammy` with the repo bind-mounted; inside the container it flips Package.swift to dynamic, builds with `--build-path .build-linux` (separate from the macOS host's `.build`), stages a `lib/` next to `skitrun`, and runs cold + warm + `--no-cache` against an input that uses helpers.

## Verified flows

From `Docs/research/poc-step7.sh` inside `swift:6.0-jammy` (aarch64):

| Flow | Time | Notes |
| --- | ---: | --- |
| Cold (helpers compile + output cache miss) | 0.73s | swiftc spawns for helpers, swift interprets the wrapped input |
| Warm (output cache hit) | 0.26s | no swift spawn |
| `--no-cache` | 0.30s | swift spawn, helpers reused from cache |

Rendered output for the demo `Person` struct matches the macOS step 5 output exactly — same SyntaxKit, same generator, no platform-specific quirks in the rendered code.

## Linux-only surprises

- **`Process.waitUntilExit()` hangs on already-exited children.** This was the biggest find. Foundation's `Process.waitUntilExit()` on `swift:6.0-jammy/aarch64` blocks indefinitely even when the child has clearly exited (stdout EOF observed, all 76 bytes of `swift --version` already read). Fix applied to all three callers (`captureSwiftVersion`, `compileHelpers`, `runSwift`): set `process.terminationHandler = { _ in semaphore.signal() }` before `run()`, then `semaphore.wait()` instead of `waitUntilExit()`. Took down a 20-minute mystery hang.
- **Stdout/stderr pipe drain order matters.** Linux pipe buffers are ~64 KB; reading sequentially after waiting for child exit deadlocks when the child fills either pipe. `runSwift` now drains both pipes concurrently via `DispatchGroup` + a `PipeDataBox` class (the boxing satisfies Swift 6 strict-concurrency without `@unchecked Sendable` on local vars). `compileHelpers` only needs to drain stderr (stdout goes to `/dev/null`), but drains before the wait for the same reason.
- **`-Xlinker -install_name @rpath/...` is Mach-O specific.** Errors out on Linux's GNU ld. Wrapped in `#if !os(Linux)` in `compileHelpers`. The `-Xlinker -rpath -Xlinker <dir>` flag still works on both platforms and is what actually locates the dylib at runtime.
- **`/usr/bin/time` isn't installed in `swift:6.0-jammy` by default.** Demo script uses the bash builtin `time` for timing, which writes a different format but is portable.
- **`swift build --product skitrun` alone doesn't emit `libSyntaxKit.so`.** The first `poc-step7.sh` draft scoped the build to just the executable, which produced a 60 MB statically-linked binary and no dylib at all. Plain `swift build` (all products) emits both `libSyntaxKit.so` and `skitrun`, matching the macOS steps 5-6 scripts.
- **First-time build cost.** Cold dependency resolution + boringssl C compile (pulled in by `swift-crypto` on Linux where CommonCrypto isn't available) takes ~3 min in `swift:6.0-jammy/aarch64`. Subsequent runs reuse `.build-linux/` and finish in ~40s.
- **Crypto on Linux brings boringssl.** `swift-crypto` statically links boringssl on non-Apple platforms. `skitrun`'s Linux binary is therefore noticeably larger than the macOS one (boringssl C blobs add up). Not a correctness issue, just a size note for future packaging.

## What's next

The 7-step POC ladder is **complete**. With this commit:

- Cold-start cost has been measured on both platforms.
- The bundled-dylib + script-mode `swift` invocation works on macOS and Linux.
- Folder mode, helpers, and the rendered-output cache all behave the same way on both.

The remaining bullets in [`codegen-cli-design.md` §7](./codegen-cli-design.md#7-what-we-still-need-to-verify) — timeouts, the splice-fidelity audit beyond the demo inputs, `@main`/attribute behavior in script-mode swift, the multi-file output question, and the web-server form — are now the natural next conversation. None of them block productizing the CLI; all of them are scope decisions rather than open technical risks.
