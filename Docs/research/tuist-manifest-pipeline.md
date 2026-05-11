# How Tuist Evaluates Manifests

> Phase 1 deliverable for [issue #154](https://github.com/brightdigit/SyntaxKit/issues/154).
> Source: read of `tuist/tuist@main` and `swiftlang/swift-package-manager@main` via GitHub. Every behavioral claim cites a file/line in those repos.

## TL;DR

- **Manifest is run, not pre-compiled to an artifact.** Tuist invokes `/usr/bin/xcrun swift <Project.swift>` in Swift script/interpreter mode with `-I/-L/-F` pointing at `ProjectDescription.framework` (`cli/Sources/TuistLoader/Loaders/ManifestLoader.swift:374-528`). There is no separate `.o`/executable for the manifest itself.
- **JSON over stdout, token-delimited.** The manifest's `Project(...)` initializer calls `dumpIfNeeded(self)` (`cli/Sources/ProjectDescription/Dump.swift:3-14`) which `JSONEncoder`s `self` and prints it bracketed by `TUIST_MANIFEST_START` / `TUIST_MANIFEST_END`; the host scans stdout for those tokens and `JSONDecoder`s the slice between them (`ManifestLoader.swift:119-120, 347-365`).
- **Helpers are real dylibs.** Files under `<root>/Tuist/ProjectDescriptionHelpers/` are compiled by a separate `swiftc -emit-module -emit-library -parse-as-library` invocation into `lib<Name>.dylib`, cached on disk, and added to the manifest's `swift` invocation via `-I/-L/-F/-l<Name>` (`cli/Sources/TuistLoader/ProjectDescriptionHelpers/ProjectDescriptionHelpersBuilder.swift:174-298`).
- **Two-layer cache.** The helpers module is keyed by an md5 of (file SHA-256s + Tuist version + Swift toolchain version + macOS version + macOS SDK version + tuist env vars + DEBUG flag) (`ProjectDescriptionHelpersHasher.swift:34-55`). The decoded manifest JSON itself is cached in `~/.tuist/Cache/Manifests`, keyed by (manifest SHA-256 + helpers hash + plugins hash + env hash + sandbox flag + Tuist version + cache schema version) (`CachedManifestLoader.swift:181-275`).
- **Sandboxed.** On macOS the whole `xcrun swift …` command is wrapped in `sandbox-exec -p <profile>` by default; the profile denies everything and re-allows only read access to the project path, Xcode, the `ProjectDescription` search paths, and `/private/tmp` + `/private/var` for writes (`ManifestLoader.swift:492-574`).

## 1. Compilation pipeline

The manifest is **not** compiled by Tuist to a separate artifact — it is run with `swift` in interpreter mode. Argument construction lives in `ManifestLoader.buildArguments(_:at:disableSandbox:)`:

```swift
// cli/Sources/TuistLoader/Loaders/ManifestLoader.swift:392-401
var arguments = [
    "/usr/bin/xcrun",
    "swift",
    "-suppress-warnings",
    "-I", searchPaths.includeSearchPath.pathString,
    "-L", searchPaths.librarySearchPath.pathString,
    "-F", searchPaths.frameworkSearchPath.pathString,
    "-l\(frameworkName)",
    "-framework", frameworkName,
]
```

Then helpers are stitched in (`ManifestLoader.swift:423-428`):

```swift
let projectDescriptionHelperArguments = projectDescriptionHelperModules.flatMap { [
    "-I", $0.path.parentDirectory.pathString,
    "-L", $0.path.parentDirectory.pathString,
    "-F", $0.path.parentDirectory.pathString,
    "-l\($0.name)",
] }
```

The manifest path itself is appended last (`ManifestLoader.swift:478`), and `--tuist-dump` is added by the caller (`ManifestLoader.swift:344`). There is **no** `-target`, `-sdk`, `-module-name`, `-emit-executable`, or `-emit-library` on the manifest run — those are SwiftPM-style flags that Tuist deliberately avoids for the manifest. The implicit target/SDK come from `xcrun swift` itself (i.e. from the active Xcode selected via `xcode-select`).

**For `Package.swift` (the `.packageSettings` case)**, Tuist additionally points `-I/-L/-F` at `XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI`, links `-lPackageDescription`, and passes `-package-description-version <toolsVersion> -D TUIST` and a JSON-encoded `-context <PackageDescriptionContext>` argument that SwiftPM's `PackageDescription` runtime expects (`ManifestLoader.swift:430-490`).

**Helpers compilation** uses `swiftc` directly (`ProjectDescriptionHelpersBuilder.swift:264-298`):

```swift
var command: [String] = [
    "/usr/bin/xcrun", "swiftc",
    "-module-name", moduleName,
    "-emit-module",
    "-emit-module-path", outputDirectory.appending(component: "\(moduleName).swiftmodule").pathString,
    "-parse-as-library",
    "-emit-library",
    "-suppress-warnings",
    "-I", projectDescriptionSearchPaths.includeSearchPath.pathString,
    "-L", projectDescriptionSearchPaths.librarySearchPath.pathString,
    "-F", projectDescriptionSearchPaths.frameworkSearchPath.pathString,
    "-working-directory", outputDirectory.pathString,
]
// + helper-module flags + `-framework ProjectDescription` (or `-lProjectDescription` when dylib) + all *.swift sources
```

The helper artifact is a dylib named `lib<Name>.dylib` (`ProjectDescriptionHelpersBuilder.swift:188-190`).

## 2. Execution model

It's model **(b) — `Process`-spawn + parse stdout**. There is no `dlopen`, no exported C symbol, no plugin entry point. `loadDataForManifest` simply runs the constructed `arguments` via `CommandRunner.capture(...)`:

```swift
// cli/Sources/TuistLoader/Loaders/ManifestLoader.swift:347-365
let string = try await commandRunner.capture(
    arguments: arguments,
    environment: Environment.current.manifestLoadingVariables
)

guard let startTokenRange = string.range(of: ManifestLoader.startManifestToken, options: .literal),
      let endTokenRange = string.range(of: ManifestLoader.endManifestToken, options: [.literal, .backwards])
else {
    return string.data(using: .utf8)!
}
// ... slice out the JSON ...
let manifest = string[startTokenRange.upperBound ..< endTokenRange.lowerBound]
return manifest.data(using: .utf8)!
```

The host scans the entire captured stdout for `TUIST_MANIFEST_START` and `TUIST_MANIFEST_END` (`ManifestLoader.swift:119-120`). Anything *before* the start token and *after* the end token is treated as user-visible log output and re-emitted via `Logger.current.notice(...)` (`ManifestLoader.swift:358-362`). This means a manifest can `print(…)` debug output *and* still be parsed correctly — a useful side-effect of the token-delimited design.

The slice between the tokens is utf8-decoded and passed straight to `JSONDecoder().decode(T.self, from: data)` (`ManifestLoader.swift:256-257`).

## 3. Bridging format

JSON, generated by `JSONEncoder` on the manifest side and `JSONDecoder` on the host side.

**Encode site** (manifest process): `cli/Sources/ProjectDescription/Dump.swift:3-14`:

```swift
func dumpIfNeeded(_ entity: some Encodable) {
    guard !ProcessInfo.processInfo.arguments.isEmpty,
          ProcessInfo.processInfo.arguments.contains("--tuist-dump")
    else { return }
    let encoder = JSONEncoder()
    let data = try! encoder.encode(entity)
    let manifest = String(data: data, encoding: .utf8)!
    print("TUIST_MANIFEST_START")
    print(manifest)
    print("TUIST_MANIFEST_END")
}
```

`dumpIfNeeded(self)` is invoked from inside the *initializer* of each top-level manifest type. For example, `Project.init(...)` ends with `dumpIfNeeded(self)` (`cli/Sources/ProjectDescription/Project.swift:109`). This is what makes a bare `let _ = Project(...)` self-publishing — the user never has to call anything; constructing the value at the top level *is* the side-effect.

**Decode site** (host process): `cli/Sources/TuistLoader/Loaders/ManifestLoader.swift:127, 175, 257`:

```swift
private let decoder: JSONDecoder
…
return try decoder.decode(T.self, from: data)
```

All top-level `ProjectDescription` types (`Project`, `Workspace`, `Config`, `Template`, `Plugin`, `PackageSettings`) are `Codable` — that's what allows the same `Decodable` constraint on `loadManifest<T: Decodable>(...)` (`ManifestLoader.swift:244`) to handle every manifest kind.

Note the asymmetry: the manifest side imports `ProjectDescription` and produces `ProjectDescription.Project`; the host side decodes into the **same** `ProjectDescription.Project` Swift type (`ManifestLoading.loadProject` returns `ProjectDescription.Project`), and only later does `ManifestModelConverter` / `Project+ManifestMapper.swift` map that into `XcodeGraph.Project` (the internal model). So `ProjectDescription` plays a dual role: API surface for users + DTO/IR for the bridge.

## 4. ProjectDescriptionHelpers

The flow is: locate → hash → compile-or-reuse → splice flags into the manifest `swift` command.

**Locate** (`HelpersDirectoryLocator.swift:37-44`):

```swift
public func locate(at: AbsolutePath) async throws -> AbsolutePath? {
    guard let rootDirectory = try await rootDirectoryLocator.locate(from: at) else { return nil }
    let helpersDirectory = rootDirectory
        .appending(component: Constants.tuistDirectoryName)      // "Tuist"
        .appending(component: Constants.helpersDirectoryName)    // "ProjectDescriptionHelpers"
    if try await !fileSystem.exists(helpersDirectory) { return nil }
    return helpersDirectory
}
```

So the discovery rule is literally: walk up from the manifest's directory to the project root, then look for `Tuist/ProjectDescriptionHelpers/`. If absent, helpers are skipped.

**Build** (`ProjectDescriptionHelpersBuilder.swift:174-255`): each helpers directory is hashed (see section 5), the hash becomes a subdirectory name under the on-disk cache, and the build is gated on whether that directory already exists. If not, files are globbed (`**/*.swift`), `swiftc` runs into a sibling **staging directory** (`<hash>.tmp.<pid>.<uuid>`) and is then atomically `rename(2)`'d into place (`ProjectDescriptionHelpersBuilder.swift:204-244`) — explicitly designed to be safe under concurrent Tuist processes.

**Plugin helpers** (`ProjectDescriptionHelpersBuilder.swift:132-144`) get built first because local helpers may import plugin helpers but not vice-versa. The plugin helper modules are then passed in as `customProjectDescriptionHelperModules` to the local helpers compile, so the local helpers can `import <PluginHelpersModule>`.

**Splicing into the manifest invocation** (`ManifestLoader.swift:405-428`): for `.project`, `.template`, `.workspace`, `.packageSettings` manifests, the helpers builder is called; for `.config`, `.plugin`, `.package`, helpers are *not* built (so you can't `import ProjectDescriptionHelpers` from `Tuist.swift`/`Plugin.swift` — the loader logs a clear error if you try, see `logUnexpectedImportErrorIfNeeded`, `ManifestLoader.swift:576-592`).

In-process the builder also memoizes via `builtHelpers: ThreadSafe<[AbsolutePath: Task<…>]>` (`ProjectDescriptionHelpersBuilder.swift:69, 180-252`), so within one Tuist invocation a helpers directory is compiled at most once even if many manifests are loaded.

## 5. Caching

There are **two** caches; both contribute to the "manifest didn't change → skip work" property.

**Helpers cache** (`ProjectDescriptionHelpersHasher.swift:34-55`):

```swift
let fileHashes = try await fileSystem
    .glob(directory: helpersDirectory, include: ["**/*.swift"])
    .collect()
    .sorted()
    .compactMap { $0.sha256() }
    .compactMap { $0.compactMap { byte in String(format: "%02x", byte) }.joined() }
let tuistEnvVariables = Environment.current.manifestLoadingVariables.map { "\($0.key)=\($0.value)" }.sorted()
let swiftlangVersion = try await SwiftVersionProvider.current.swiftlangVersion()
let macosVersion = machineEnvironment.macOSVersion
let macosSDKVersion = try await MacOSSDKVersionProvider.current.macOSSDKVersion()
…
let identifiers =
    [macosVersion, macosSDKVersion, swiftlangVersion, tuistVersion] + fileHashes + tuistEnvVariables + ["\(debug)"]
return identifiers.joined(separator: "-").md5
```

So the helpers cache key is sensitive to: per-file SHA-256s (sorted), macOS version, macOS SDK version, Swift compiler/toolchain version, Tuist version, every `TUIST_*` env var, and DEBUG vs release Tuist build. The on-disk location is `cacheDirectoriesProvider.cacheDirectory(for: .projectDescriptionHelpers)` (`ManifestLoader.swift:402-403`), with the hash as the directory name — defaults under `~/.cache/tuist/…` on macOS / Linux per Tuist's CacheDirectoriesProvider conventions.

**Decoded-manifest cache** (`CachedManifestLoader.swift:181-275`): after the manifest has been compiled-and-run once, the resulting JSON-encoded `ProjectDescription.Project` value is itself cached at `cacheDirectoriesProvider.cacheDirectory(for: .manifests)` (default `~/.tuist/Cache/Manifests` per the class doc, `CachedManifestLoader.swift:15`), keyed by:

```swift
// CachedManifestLoader.swift:192-198
return Hashes(
    manifestHash: manifestHash,           // SHA-256 of Project.swift
    helpersHash: helpersHash,             // md5 from ProjectDescriptionHelpersHasher
    pluginsHash: try await pluginsHashCache.value?.value,
    environmentHash: environmentHash,     // md5 of TUIST_* env vars
    disableSandboxHash: disableSandboxHash
)
```

Plus a `cacheVersion` integer (`CachedManifest.currentCacheVersion = 1`, `CachedManifestLoader.swift:314`) and the Tuist version (`CachedManifestLoader.swift:268-273`) — all five must match for a cache hit. On a hit, Tuist skips spawning `swift` entirely and decodes the cached JSON directly.

## 6. Toolchain resolution

Two paths.

**For `swift` / `swiftc`**: Tuist hard-codes `/usr/bin/xcrun` (`ManifestLoader.swift:393`, `ProjectDescriptionHelpersBuilder.swift:267`) and lets xcrun resolve the toolchain. So the active Xcode (set by `xcode-select -s` or by `DEVELOPER_DIR`) determines `swift`/`swiftc`. Tuist does not appear to honor a `TOOLCHAINS=` or a custom `.xctoolchain` indirectly beyond whatever xcrun itself does.

**For the SDK / Xcode path** (only needed for `.packageSettings`): `ManifestLoader.swift:432-457`:

```swift
let xcodePath = try await {
    if let developerDir = Environment.current.variables["DEVELOPER_DIR"] {
        let developerDirPath = try AbsolutePath(validating: developerDir)
        let resolvedXcodePath = if developerDirPath.components.suffix(2) == ["Contents", "Developer"] {
            developerDirPath.parentDirectory.parentDirectory
        } else {
            developerDirPath
        }
        let manifestPath = resolvedXcodePath
            .appending(components: "Contents", "Developer", "Toolchains",
                       "XcodeDefault.xctoolchain", "usr", "lib", "swift", "pm", "ManifestAPI")
        if try await fileSystem.exists(manifestPath) {
            return resolvedXcodePath
        }
    }
    return try await XcodeController.current.selected().path
}()
```

So `DEVELOPER_DIR` is consulted first (with normalization for either form — pointing at `Xcode.app` or at `Xcode.app/Contents/Developer`), falling back to whatever `xcode-select` reports.

**For `ProjectDescription.framework` / `libProjectDescription.dylib`**: `ResourceLocator.frameworkPath` (`cli/Sources/TuistLoader/Utils/ResourceLocator.swift:52-83`) searches relative to the Tuist binary's `Bundle.bundleURL`, including a Homebrew-style `bin/` ↔ `lib/` adjacency, and honors `TUIST_FRAMEWORK_SEARCH_PATHS` (space-separated). It will accept any of `libProjectDescription.dylib`, `ProjectDescription.framework`, or `PackageFrameworks/ProjectDescription.framework` — and `ProjectDescriptionSearchPaths.pathStyle(for:)` (`cli/Sources/TuistLoader/Utils/ProjectDescriptionPaths.swift:85-93`) decides whether downstream include/library/framework search paths should be derived dylib-style or framework-style.

## 7. Failure modes

- **Syntax error / compile failure**: `swift` exits non-zero, `CommandRunner` throws `CommandError.terminated(exitCode, standardError, command)`, and the host wraps it. Two hooks (`logUnexpectedImportErrorIfNeeded`, `logPluginHelperBuildErrorIfNeeded`, `ManifestLoader.swift:576-604`) inspect stderr and surface friendlier errors for common cases (e.g. importing `ProjectDescriptionHelpers` from `Config.swift`/`Plugin.swift`, or a missing plugin helper module).
- **Runtime crash / non-zero exit**: same path — `CommandRunner.capture(...)` throws, and the loader bubbles it up.
- **No start/end tokens in stdout**: the loader does **not** error; it falls back to treating the entire stdout as the JSON payload (`ManifestLoader.swift:352-356`). The JSON decode will then fail and produce a `ManifestLoaderError.manifestLoadingFailed` with the captured payload included for debugging (`ManifestLoader.swift:259-265`).
- **Decode failure**: each `DecodingError` case (`typeMismatch`, `valueNotFound`, `keyNotFound`, `dataCorrupted`) is mapped to a tailored `manifestLoadingFailed(context:)` error message that includes the offending JSON (`ManifestLoader.swift:267-315`).
- **Missing import / unresolved module**: stderr from `swift` carries the message; the two `logXxxErrorIfNeeded` functions detect the most common culprit (default helpers from a forbidden manifest, or a plugin helper that failed its own build) and emit a targeted log line. Beyond that the raw compile error reaches the user.
- **Hang / timeout**: no process-wait timeout in `ManifestLoader` or `CommandRunner` usage. Tuist appears to wait indefinitely for the `swift` subprocess to finish. (Inferred — `grep` for `timeout|terminate|sleep` in the loader files surfaced nothing.)
- **Empty `Package.swift`** is special-cased: `loadPackageSettings` catches `manifestLoadingFailed` with `data.count == 0` and returns a default `PackageSettings()` (`ManifestLoader.swift:217-230`).
- **Sandbox**: by default on macOS, the `swift` call is wrapped in `sandbox-exec -p <profile>` (`ManifestLoader.swift:516-521`). The profile (`ManifestLoader.swift:547-574`) denies by default, then allows `process*`, `file-read-metadata`, RW under `/private/tmp` and `/private/var`, and read-only access to: the project path, the selected Xcode path, `com.apple.dt.Xcode.plist`, the three ProjectDescription search paths, the resolved `DEVELOPER_DIR`, and every helpers-module parent directory. Manifests can opt out via `disableSandbox: true` (config and plugin always run unsandboxed: `ManifestLoader.swift:195, 207, 234`).

## 8. SwiftPM comparison

SwiftPM uses model **(b)** as well but goes one extra step: it actually compiles the manifest into a **temporary executable on disk** and then `Process`-spawns *that* (`Sources/PackageLoading/ManifestLoader.swift:779-908` in `swiftlang/swift-package-manager`). In `evaluateManifest(...)`:

```swift
// swift-package-manager/Sources/PackageLoading/ManifestLoader.swift:779-786
let compiledManifestFile = tmpDir.appending("\(packageIdentity)-manifest\(executableSuffix)")
cmd += ["-o", compiledManifestFile.pathString]
```

then later (`:840, :906-908`):

```swift
var runCmd = [compiledManifestFile.pathString]
…
runResult = try await AsyncProcess.popen(arguments: runCmd, environment: environment)
```

The framework search path for `PackageDescription` comes from `self.toolchain.swiftPMLibrariesLocation.manifestLibraryPath` and is added with `-F <runtimePath.parentDirectory> -Xlinker -rpath -Xlinker <runtimePath.parentDirectory> -framework PackageDescription` (or the `-L/-lPackageDescription/-rpath` dylib variant), plus an `-target` derived from `swiftPMLibrariesLocation.manifestLibraryMinimumDeploymentTarget` (`Sources/PackageLoading/ManifestLoader.swift:721-755`). Tuist by contrast (a) skips the explicit `-target` (lets `swift` interpreter pick its default), (b) does not write an intermediate executable to disk, (c) does not use `-Xlinker -rpath` for the manifest, and (d) wraps the whole thing in `sandbox-exec`. The net effect is the same — JSON on stdout, host decodes — but Tuist's path is one process and one disk-write fewer per manifest load (offset by the heavier helpers cache).

The framework-search-path mechanics are the most directly transferable to a SyntaxKit equivalent: both tools resolve a *bundled, versioned* library that ships next to the CLI (Tuist's `ResourceLocator`, SwiftPM's `swiftPMLibrariesLocation`) and pass it via `-I/-L/-F + -framework <name>` (or `-l<name>` for dylib distributions) to a single Swift compiler invocation that *also* takes the user's manifest path as a positional argument.

## Open questions / things I couldn't determine

- **Exact `CommandRunner.capture` semantics.** Call sites read but not implementation; *assuming* it returns stdout — the token-scanning code clearly operates on stdout-style content, but it isn't verified whether `print(…)` logs from user code (stdout) and compiler errors (stderr) end up in the same string. Inferred from `logUnexpectedImportErrorIfNeeded`'s use of `CommandError.terminated(_, standardError, command)` (`ManifestLoader.swift:577`) that stderr is captured separately.
- **Timeout.** No `terminate(after:)` / `timeout:` wiring around the manifest-spawn. If the user manifest infinite-loops, Tuist appears to wait forever. Not 100% certain because the `Command` package is a separate dependency not opened here.
- **Linux behavior.** The sandbox branch is `#if os(macOS)`; on Linux the manifest runs un-sandboxed (`ManifestLoader.swift:522-524`). Did not check whether `ResourceLocator` finds the framework on Linux or only the dylib — the `ProjectDescriptionSearchPaths.Style.commandLine` branch (which derives `-I` from a sibling `Modules/` directory) suggests Linux relies on `libProjectDescription.dylib + Modules/ProjectDescription.swiftmodule`.
- **Module cache.** SwiftPM passes `-module-cache-path` (`swift-package-manager Sources/PackageLoading/ManifestLoader.swift:759-761`); Tuist does **not** set one for the manifest invocation, so the manifest run inherits the default global Swift module cache. Significance for SyntaxKit's use case not chased.
- **`Config.swift` / `Tuist.swift` special path.** Both fall through `loadConfig` → `loadManifest(.config, …, disableSandbox: true)` → same `swift` invocation, but skip helpers entirely (`ManifestLoader.swift:407-408`). Not verified whether `Tuist.swift` accepts a different framework name (the switch in `buildArguments` lumps `.config` under `frameworkName = "ProjectDescription"`).
