# Globals Audit

File-scope **functions** and **variables** (`func` / `let` / `var` declared directly in a file, not inside a type or extension). Types (`struct`/`enum`/`class`/`actor`/`protocol`) are intentionally **excluded** — the no-globals convention targets funcs and vars only.

Note: in `Sources/skit/` every listed declaration is indented because it lives inside a top-level `#if canImport(Subprocess)` block — it is still a true file-scope global. This is exactly the case a SwiftLint regex rule cannot detect.

Clean targets (no global funcs/vars): **SyntaxKit**, **SyntaxParser**, **TokenVisitor**.

Generated: 2026-06-08. Branch: `research/swift-manifest-codegen`.

---

## Sources/skit/Runner.swift

All inside `#if canImport(Subprocess)`.

### Functions
- [ ] L48 — `internal func toolchainMismatchMessage(bundle: String, local: String) -> String`
- [ ] L72 — `internal func runSingleFile(inputPath:outputPath:libPath:useCache:timeoutSeconds:) async throws`
- [ ] L110 — `internal func runDirectory(inputDir:outputDir:libPath:useCache:timeoutSeconds:) async -> Int32`
- [ ] L213 — `private func runOne(_ input: URL, libPath:useCache:timeoutSeconds:) async -> FileOutcome`
- [ ] L235 — `private func collectInputs(at inputDir: URL) throws -> [URL]`
- [ ] L267 — `private func processFile(inputPath:libPath:useCache:timeoutSeconds:) async throws -> ProcessResult`
- [ ] L336 — `private func wrap(source: String, originalPath: String) -> String`
- [ ] L417 — `private func runSwift(wrappedPath:libPath:timeoutSeconds:) async throws -> ProcessResult`
- [ ] L486 — `private func exitCode(from status: TerminationStatus) -> Int32`

### Variables
- [ ] L405 — `private let timeoutExitCode: Int32 = 124`
- [ ] L410 — `private let stdoutLimitBytes: Int = 16 * 1_024 * 1_024`
- [ ] L411 — `private let stderrLimitBytes: Int = 1 * 1_024 * 1_024`

---

## Sources/skit/Toolchain.swift

All inside `#if canImport(Subprocess)`.

### Functions
- [ ] L36 — `internal func captureSwiftVersion() async -> String?`
- [ ] L48 — `internal func syntaxKitCacheRoot() throws -> URL`

---

## Sources/DocumentationHarness/Validator.swift

### Variables
- [ ] L36 — `private let privateDefaultPathExtensions = ["md"]`

---

## Summary

| Target | Global funcs | Global vars |
|---|---:|---:|
| skit / Runner.swift | 9 | 3 |
| skit / Toolchain.swift | 2 | 0 |
| skit / OutputCache.swift | 0 | 0 |
| DocumentationHarness / Validator.swift | 0 | 1 |
| **Total** | **11** | **4** |

All `skit` globals are free functions/constants inside `#if canImport(Subprocess)` — a deliberate CLI style. `privateDefaultPathExtensions` is the lone non-skit global (a linter reverted an earlier attempt to nest it).
