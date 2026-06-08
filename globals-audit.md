# Globals Audit

File-scope **functions** and **variables** (`func` / `let` / `var` declared directly in a file, not inside a type or extension). Types (`struct`/`enum`/`class`/`actor`/`protocol`) are intentionally **excluded** — the no-globals convention targets funcs and vars only.

Note: in `Sources/skit/` every listed declaration is indented because it lives inside a top-level `#if canImport(Subprocess)` block — it is still a true file-scope global. This is exactly the case a SwiftLint regex rule cannot detect.

Clean targets (no global funcs/vars): **SyntaxKit**, **SyntaxParser**, **TokenVisitor**.

Generated: 2026-06-07. Branch: `research/swift-manifest-codegen`.

---

## Sources/skit/Runner.swift

All inside `#if canImport(Subprocess)`.

### Functions
- [ ] L66 — `internal func resolveHelpers(nearInputPath path: String, libPath: String, options: HelpersOptions) async throws -> CompiledHelpers?`
- [ ] L173 — `internal func toolchainCheck(libPath: String) async -> ToolchainCheckResult`
- [ ] L194 — `internal func toolchainMismatchMessage(bundle: String, local: String) -> String`
- [ ] L218 — `internal func runSingleFile(inputPath:outputPath:libPath:helpers:useCache:timeoutSeconds:) async throws`
- [ ] L258 — `internal func runDirectory(inputDir:outputDir:libPath:helpers:useCache:timeoutSeconds:) async -> Int32`
- [ ] L370 — `private func runOne(_ input: URL, libPath:helpers:useCache:timeoutSeconds:) async -> FileOutcome`
- [ ] L394 — `private func helpersExcludePath(inputDir: URL) -> String?`
- [ ] L408 — `private func collectInputs(at inputDir: URL, excluding excludedDir: String?) throws -> [URL]`
- [ ] L455 — `private func processFile(inputPath:libPath:helpers:useCache:timeoutSeconds:) async throws -> ProcessResult`
- [ ] L533 — `internal func wrap(source: String, originalPath: String) -> String`
- [ ] L623 — `private func runSwift(wrappedPath:libPath:helpers:timeoutSeconds:) async throws -> ProcessResult`
- [ ] L708 — `private func exitCode(from status: TerminationStatus) -> Int32`

### Variables
- [ ] L157 — `internal let toolchainStampFilename = "swift-version.txt"`
- [ ] L602 — `private let timeoutExitCode: Int32 = 124`
- [ ] L607 — `private let stdoutLimitBytes: Int = 16 * 1_024 * 1_024`
- [ ] L608 — `private let stderrLimitBytes: Int = 1 * 1_024 * 1_024`

---

## Sources/skit/Helpers.swift

All inside `#if canImport(Subprocess)`.

### Functions
- [ ] L40 — `internal func dylibFilename(forLibrary name: String) -> String`
- [ ] L66 — `internal func discoverHelpersDir(near inputURL: URL) -> URL?`
- [ ] L86 — `internal func collectHelperSources(in helpersDir: URL) throws -> [URL]`
- [ ] L116 — `internal func buildHelpers(helpersDir: URL, libPath: String) async throws -> CompiledHelpers?`
- [ ] L182 — `private func compileHelpers(sources: [URL], into outDir: URL, libPath: String) async throws`
- [ ] L239 — `private func helpersCacheKey(sources: [URL], libPath: String) async throws -> String`
- [ ] L263 — `internal func captureSwiftVersion() async -> String?`
- [ ] L275 — `internal func libStamp(libPath: String) -> String?`
- [ ] L285 — `internal func syntaxKitCacheRoot() throws -> URL`

### Variables
- [ ] L37 — `internal let helpersModuleName = "SyntaxKitHelpers"`
- [ ] L49 — `private let helpersCacheSchemaVersion = "v1"`

---

## Sources/skit/OutputCache.swift

All inside `#if canImport(Subprocess)`.

### Functions
- [ ] L41 — `internal func outputCacheKey(inputSource: String, helpers: CompiledHelpers?, libPath: String) async -> String`
- [ ] L85 — `internal func lookupCachedOutput(key: String) -> Data?`
- [ ] L92 — `internal func storeCachedOutput(key: String, data: Data) throws`
- [ ] L126 — `private func outputCacheDir(for key: String) throws -> URL`

### Variables
- [ ] L35 — `private let outputCacheSchemaVersion = "v1"`

---

## Sources/DocumentationHarness/Validator.swift

### Variables
- [ ] L36 — `private let privateDefaultPathExtensions = ["md"]`

---

## Summary

| Target | Global funcs | Global vars |
|---|---:|---:|
| skit / Runner.swift | 12 | 4 |
| skit / Helpers.swift | 9 | 2 |
| skit / OutputCache.swift | 4 | 1 |
| DocumentationHarness / Validator.swift | 0 | 1 |
| **Total** | **25** | **8** |

All `skit` globals are free functions/constants inside `#if canImport(Subprocess)` — a deliberate CLI style. `privateDefaultPathExtensions` is the lone non-skit global (a linter reverted an earlier attempt to nest it).
