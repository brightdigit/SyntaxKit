# Globals Audit

File-scope **functions** and **variables** (`func` / `let` / `var` declared directly in a file, not inside a type or extension). Types (`struct`/`enum`/`class`/`actor`/`protocol`) are intentionally **excluded** — the no-globals convention targets funcs and vars only.

Note: in `Sources/skit/` every listed declaration is indented because it lives inside a top-level `#if canImport(Subprocess)` block — it is still a true file-scope global. This is exactly the case a SwiftLint regex rule cannot detect.

Clean targets (no global funcs/vars): **SyntaxKit**, **SyntaxParser**, **TokenVisitor**.

Generated: 2026-06-07. Branch: `research/swift-manifest-codegen`.

---

## Sources/skit/Runner.swift

All inside `#if canImport(Subprocess)`.

### Functions
- [ ] `internal func toolchainMismatchMessage(bundle: String, local: String) -> String`
- [ ] `internal func runSingleFile(inputPath:outputPath:libPath:useCache:timeoutSeconds:) async throws`
- [ ] `internal func runDirectory(inputDir:outputDir:libPath:useCache:timeoutSeconds:) async -> Int32`
- [ ] `private func runOne(_ input: URL, libPath:useCache:timeoutSeconds:) async -> FileOutcome`
- [ ] `private func collectInputs(at inputDir: URL) throws -> [URL]`
- [ ] `private func processFile(inputPath:libPath:useCache:timeoutSeconds:) async throws -> ProcessResult`
- [ ] `internal func wrap(source: String, originalPath: String) -> String`
- [ ] `private func runSwift(wrappedPath:libPath:timeoutSeconds:) async throws -> ProcessResult`
- [ ] `private func exitCode(from status: TerminationStatus) -> Int32`

### Variables
- [ ] `private let timeoutExitCode: Int32 = 124`
- [ ] `private let stdoutLimitBytes: Int = 16 * 1_024 * 1_024`
- [ ] `private let stderrLimitBytes: Int = 1 * 1_024 * 1_024`

---

## Sources/skit/Toolchain.swift

All inside `#if canImport(Subprocess)`.

### Functions
- [ ] `internal func dylibFilename(forLibrary name: String) -> String`
- [ ] `internal func captureSwiftVersion() async -> String?`
- [ ] `internal func libStamp(libPath: String) -> String?`
- [ ] `internal func syntaxKitCacheRoot() throws -> URL`

---

## Sources/skit/OutputCache.swift

All inside `#if canImport(Subprocess)`.

### Functions
- [ ] `internal func outputCacheKey(inputSource: String, libPath: String) async -> String`
- [ ] `internal func lookupCachedOutput(key: String) -> Data?`
- [ ] `internal func storeCachedOutput(key: String, data: Data) throws`
- [ ] `private func outputCacheDir(for key: String) throws -> URL`

### Variables
- [ ] `private let outputCacheSchemaVersion = "v1"`

---

## Sources/DocumentationHarness/Validator.swift

### Variables
- [ ] L36 — `private let privateDefaultPathExtensions = ["md"]`

---

## Summary

| Target | Global funcs | Global vars |
|---|---:|---:|
| skit / Runner.swift | 9 | 3 |
| skit / Toolchain.swift | 4 | 0 |
| skit / OutputCache.swift | 4 | 1 |
| DocumentationHarness / Validator.swift | 0 | 1 |
| **Total** | **17** | **5** |

All `skit` globals are free functions/constants inside `#if canImport(Subprocess)` — a deliberate CLI style. `privateDefaultPathExtensions` is the lone non-skit global (a linter reverted an earlier attempt to nest it).
