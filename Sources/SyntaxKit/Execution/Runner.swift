//
//  Runner.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

// Render lifecycle (per `Runner` call):
//   1. Bundle.main.resolveLibPath   — find lib/ (explicit flag → env → adjacent → brew)
//   2. ToolchainCheckResult.init    — compare bundle stamp to `swift --version`
//   3. Runner.renderFile / .renderDirectory — single- or batch-input mode
//   4. processFile (per input)      — load → cache lookup → wrap → spawn → cache store
//   5. wrap                         — hoist imports, wrap body in Group { … }, #sourceLocation
//   6. runSwift                     — spawn `swift` with timeout watchdog
// See Docs/skit.md for design rationale and trade-offs.

/// Renders SyntaxKit DSL inputs into Swift source. `Runner` is the SDK-shaped
/// entry point: methods return rendered data (`SingleFileRender`) or
/// structured per-file outcomes (`DirectoryRender`) and throw typed
/// `RunError`s; callers — CLI, build plugin, in-process driver — decide what
/// to do with stdout, stderr, exit codes, and so on.
///
/// Constructed once per render session; `Sendable` so a single value can be
/// shared across the concurrent per-input tasks in directory mode.
package struct Runner: Sendable {
  /// Directory holding `libSyntaxKit.{dylib,so}` + swiftmodules; reused for
  /// the spawned `swift`'s `-I`/`-L`/`-rpath` flags.
  private let libPath: String
  /// Output cache shared across every input, or nil under `--no-cache`.
  private let cache: OutputCache?
  /// Per-input watchdog in seconds; `0` opts out of the timeout race.
  private let timeoutSeconds: Int
  /// Backend that actually spawns `swift` for one `SwiftInvocation`. Injected
  /// by the caller (skit supplies a Subprocess-based implementation).
  private let run: @Sendable (SwiftInvocation) async throws -> ProcessResult

  package init(
    libPath: String,
    cache: OutputCache?,
    timeoutSeconds: Int,
    run: @Sendable @escaping (SwiftInvocation) async throws -> ProcessResult
  ) {
    self.libPath = libPath
    self.cache = cache
    self.timeoutSeconds = timeoutSeconds
    self.run = run
  }

  // MARK: - Single-file mode

  /// Renders one input and returns the rendered bytes plus any compiler
  /// diagnostics. No file IO, no stdout/stderr writes — the caller decides
  /// where the result goes.
  ///
  /// On a non-zero subprocess exit, throws `RunError.renderFailed(exitCode:
  /// stderr:)` carrying the toolchain's diagnostic. Any Foundation/Subprocess
  /// failure (file read, spawn) is wrapped in `RunError.unexpected`.
  package func renderFile(input: String) async throws(RunError) -> SingleFileRender {
    // Render the input. `processFile` may hit the output cache and skip the
    // spawn entirely; either way the result has the same shape.
    let result: ProcessResult
    do {
      result = try await processFile(inputPath: input)
    } catch let error as RunError {
      throw error
    } catch {
      throw RunError.unexpected(error)
    }
    // Non-zero subprocess exit is reported as a typed failure carrying both
    // the code and the (path-rewritten) toolchain diagnostic.
    guard result.exitCode == 0 else {
      throw RunError.renderFailed(exitCode: result.exitCode, stderr: result.stderr)
    }
    return SingleFileRender(stdout: result.stdout, stderr: result.stderr)
  }

  // MARK: - Per-file work

  /// The per-input render pipeline: load source → consult the output cache →
  /// (on miss) wrap → spawn `swift` → rewrite diagnostics → store the result
  /// in the cache. The temp wrapper file is created in a per-run tmp dir and
  /// torn down by `defer` whether the spawn succeeded or not. `internal` so
  /// the directory-mode extension (`Runner+Directory.swift`) can reuse it.
  internal func processFile(inputPath: String) async throws -> ProcessResult {
    // Load the input source. Anything past this point keys off these bytes.
    let inputURL = URL(fileURLWithPath: inputPath).standardizedFileURL
    let absoluteInputPath = inputURL.path
    let source = try String(contentsOf: inputURL, encoding: .utf8)

    // Compute the output cache key (nil under `--no-cache` or when the cache
    // root couldn't be derived at startup). Mixes input bytes, toolchain
    // version, libSyntaxKit stamp, and sorted SKIT_*/SYNTAXKIT_* env vars
    // — see `OutputCache.key(forInput:libPath:)`.
    let cacheKey: String? = cache?.key(forInput: source, libPath: libPath)
    // Cache hit: skip the wrap+spawn entirely and return the stored output.
    if let cache, let cacheKey, let cached = cache.lookup(key: cacheKey) {
      return ProcessResult(exitCode: 0, stdout: cached, stderr: "")
    }

    // Wrap the user's input into a complete Swift program that imports
    // SyntaxKit, runs the body inside a Group { … } builder, and prints the
    // result. See `WrappedSource` for the exact template.
    let wrapped = WrappedSource(source: source, originalPath: absoluteInputPath).rendered

    // Spill the wrapped program to a per-invocation temp dir. The dir is
    // cleaned up unconditionally so a failed spawn doesn't leak files.
    let tmpDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("skit-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmpDir) }

    let wrappedURL = tmpDir.appendingPathComponent("Input.wrapped.swift")
    try wrapped.write(to: wrappedURL, atomically: true, encoding: .utf8)

    // Spawn `swift` on the wrapped file (with timeout watchdog). stdout is
    // the rendered Swift source; stderr is compiler diagnostics, if any.
    let raw = try await runSwift(wrappedPath: wrappedURL.path)
    // #sourceLocation maps body diagnostics back to the input file. Errors in
    // the preamble (lines outside the body) still reference the wrapper —
    // rewrite literal occurrences of its path so users see something coherent.
    let stderr = raw.stderr.replacingOccurrences(
      of: wrappedURL.path,
      with: absoluteInputPath
    )

    // Store on the way out. `try?` is deliberate: a cache write failure is
    // not a render failure. The next run will simply miss and re-spawn.
    if let cache, let cacheKey, raw.exitCode == 0 {
      try? cache.store(key: cacheKey, data: raw.stdout)
    }

    return ProcessResult(exitCode: raw.exitCode, stdout: raw.stdout, stderr: stderr)
  }

  // MARK: - Spawning swift

  /// Exit code returned when the spawned `swift` is killed by skit's timeout
  /// watchdog. Matches POSIX `timeout(1)`.
  private static let timeoutExitCode: Int32 = 124

  /// Spawns `swift` (via the injected `run` backend) on the wrapped input file.
  /// When `timeoutSeconds > 0` the spawn races a sleep task in a throwing
  /// task group; the loser is cancelled. On timeout, returns exit 124 with
  /// a one-line stderr message — matching POSIX `timeout(1)`'s convention.
  private func runSwift(wrappedPath: String) async throws -> ProcessResult {
    let invocation = SwiftInvocation(libPath: libPath, wrappedPath: wrappedPath)

    // The actual backend call, wrapped in a closure so the task-group race
    // below can hold a single Sendable reference to it.
    let operation: @Sendable () async throws -> SwiftRunOutcome = {
      .completed(try await self.run(invocation))
    }

    // Race the invocation against a sleep watchdog; whichever finishes first
    // wins, the other is cancelled. `timeoutSeconds <= 0` opts out of the
    // race entirely (useful for debugging genuinely long codegen).
    let outcome: SwiftRunOutcome
    if timeoutSeconds <= 0 {
      outcome = try await operation()
    } else {
      outcome = try await Task.timeout(.seconds(timeoutSeconds), operation: operation) ?? .timedOut
    }

    // Normalize both outcomes into a single ProcessResult shape.
    switch outcome {
    case .completed(let result):
      return result
    case .timedOut:
      return ProcessResult(
        exitCode: Self.timeoutExitCode,
        stdout: Data(),
        stderr: "skit: timed out after \(timeoutSeconds)s\n"
      )
    }
  }
}
