# Globals Audit

File-scope **functions** and **variables** (`func` / `let` / `var` declared directly in a file, not inside a type or extension). Types (`struct`/`enum`/`class`/`actor`/`protocol`) are intentionally **excluded** — the no-globals convention targets funcs and vars only.

Note: in `Sources/skit/` every listed declaration is indented because it lives inside a top-level `#if canImport(Subprocess)` block — it is still a true file-scope global. This is exactly the case a SwiftLint regex rule cannot detect.

Clean targets (no global funcs/vars): **SyntaxKit**, **SyntaxParser**, **TokenVisitor**.

Generated: 2026-06-08. Branch: `research/swift-manifest-codegen`.

---

## Sources/skit/Runner.swift

Resolved — all eight functions and three constants were lifted into a new
`internal struct Runner: Sendable` (in the same file) that holds the
per-invocation configuration (`libPath`, `cache`, `timeoutSeconds`). The lone
`internal` entry point is `callAsFunction(input:output:)` (invoked as
`runner(input:output:)`); everything else is private:
- [x] `runSingleFile` / `runDirectory` → **private** mode methods, dispatched by `callAsFunction` via `RunInput`.
- [x] `runOne` / `processFile` / `runSwift` → config-dependent private instance methods.
- [x] `collectInputs` / `wrap` / `exitCode` → pure `private static` methods.
- [x] `timeoutExitCode` / `stdoutLimitBytes` / `stderrLimitBytes` → `private static let` constants.
- [x] `toolchainMismatchMessage(bundle:local:)` → `fileprivate` method on `Skit.Run` in `Skit+Run.swift` (moved earlier).

---

## Sources/skit/Toolchain.swift

Resolved — file removed. Both globals were lifted into types/extensions:
- [x] `captureSwiftVersion()` → `fileprivate` method on `Skit.Run` in `Skit+Run.swift`.
- [x] `syntaxKitCacheRoot()` → `ProcessInfo.syntaxKitCacheRoot(default:)` in `ProcessInfo+SyntaxKitCacheRoot.swift`; the platform default is now a `private static let defaultCacheRoot` on `OutputCache`.

---

## Sources/DocumentationHarness/Validator.swift

### Variables
- [ ] L36 — `private let privateDefaultPathExtensions = ["md"]`

---

## Summary

| Target | Global funcs | Global vars |
|---|---:|---:|
| skit / Runner.swift | 0 | 0 |
| skit / Toolchain.swift (removed) | 0 | 0 |
| skit / OutputCache.swift | 0 | 0 |
| DocumentationHarness / Validator.swift | 0 | 1 |
| **Total** | **0** | **1** |

All `skit` file-scope globals have been lifted into types/extensions. `privateDefaultPathExtensions` in `DocumentationHarness/Validator.swift` is the lone remaining global (a linter reverted an earlier attempt to nest it).
