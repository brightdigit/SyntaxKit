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

#if canImport(Subprocess)

  import ArgumentParser
  import Foundation
  import Subprocess

  // Run lifecycle (per `skit run` invocation):
  //   1. Bundle.main.resolveLibPath   — find lib/ (explicit flag → env → adjacent → brew)
  //   2. ToolchainCheckResult.init    — compare bundle stamp to `swift --version`
  //   3. Runner.runSingleFile / .runDirectory — single- or batch-input mode
  //   4. processFile (per input)      — load → cache lookup → wrap → spawn → cache store
  //   5. wrap                         — hoist imports, wrap body in Group { … }, #sourceLocation
  //   6. runSwift                     — spawn `swift` with timeout watchdog
  // See Docs/skit.md for design rationale and trade-offs.

  /// Renders SyntaxKit DSL inputs into Swift source, holding the per-invocation
  /// configuration (`libPath`, `cache`, `timeoutSeconds`) so the individual
  /// inputs don't have to thread it through every call. Constructed once per
  /// `skit run` in `Skit.Run.run`; `Sendable` so a single value can be shared
  /// across the concurrent `runOne` tasks in directory mode.
  internal struct Runner: Sendable {
    /// Directory holding `libSyntaxKit.{dylib,so}` + swiftmodules; reused for
    /// the spawned `swift`'s `-I`/`-L`/`-rpath` flags.
    private let libPath: String
    /// Output cache shared across every input, or nil under `--no-cache`.
    private let cache: OutputCache?
    /// Per-input watchdog in seconds; `0` opts out of the timeout race.
    private let timeoutSeconds: Int

    internal init(libPath: String, cache: OutputCache?, timeoutSeconds: Int) {
      self.libPath = libPath
      self.cache = cache
      self.timeoutSeconds = timeoutSeconds
    }

    // MARK: - Dispatch

    /// Classifies `input` (single file vs. directory) and renders it. Directory
    /// mode surfaces its batch exit code via `ExitCode` (so a partial-failure
    /// batch returns 1); single-file mode renders to file/stdout and may call
    /// `exit()` directly on a non-zero subprocess result. Throws a
    /// `ValidationError` if the path doesn't exist, or if a directory input
    /// wasn't given an explicit `-o`.
    func callAsFunction(input: String, output: String?) async throws {
      switch try RunInput.resolve(input: input, output: output) {
      case .directory(let inputDir, let outputDir):
        let exitCode = await runDirectory(inputDir: inputDir, outputDir: outputDir)
        throw ExitCode(exitCode)
      case .singleFile(let inputPath, let outputPath):
        try await runSingleFile(inputPath: inputPath, outputPath: outputPath)
      }
    }

    // MARK: - Single-file mode

    /// Runs `processFile` on a single input and writes its rendered Swift to
    /// `outputPath` (or stdout when nil). Any stderr from the spawned `swift`
    /// is surfaced verbatim. On a non-zero subprocess exit, calls `exit()`
    /// directly — the caller in `Skit.Run.run()` won't see a thrown error in
    /// that path.
    private func runSingleFile(inputPath: String, outputPath: String?) async throws {
      // Render the input. `processFile` may hit the output cache and skip the
      // spawn entirely; either way the result has the same shape.
      let result = try await processFile(inputPath: inputPath)
      // Surface diagnostics from the spawned `swift` before deciding success.
      if !result.stderr.isEmpty {
        FileHandle.standardError.write(Data(result.stderr.utf8))
      }
      // Non-zero subprocess exit propagates as a process exit. We don't write
      // partial output in that case.
      guard result.exitCode == 0 else {
        exit(result.exitCode)
      }
      // Deliver the rendered output to file or stdout.
      if let outputPath {
        try result.stdout.write(to: URL(fileURLWithPath: outputPath))
      } else {
        FileHandle.standardOutput.write(result.stdout)
      }
    }

    // MARK: - Folder mode

    /// Walks `inputDir` for `.swift` inputs, processes them concurrently (up to
    /// the active core count), and mirrors the rendered output into `outputDir`.
    /// A failure on one input does not abort the batch — successful peers are
    /// still written. Returns 0 if every input succeeded, 1 otherwise.
    private func runDirectory(inputDir: String, outputDir: String) async -> Int32 {
      let inputURL = URL(fileURLWithPath: inputDir).standardizedFileURL
      let outputURL = URL(fileURLWithPath: outputDir).standardizedFileURL

      // Phase 1: enumerate inputs.
      let inputs: [URL]
      do {
        inputs = try Self.collectInputs(at: inputURL)
      } catch {
        FileHandle.standardError.write(Data("skit: failed to walk \(inputDir): \(error)\n".utf8))
        return 1
      }

      if inputs.isEmpty {
        FileHandle.standardError.write(Data("skit: no .swift inputs under \(inputDir)\n".utf8))
        return 0
      }

      // Phase 2: bounded-concurrency processing. Cap is the active core count
      // so a 200-file batch doesn't fork 200 simultaneous `swift` processes.
      let maxConcurrent = max(1, ProcessInfo.processInfo.activeProcessorCount)

      var outcomes: [FileOutcome] = []
      var iterator = inputs.makeIterator()

      await withTaskGroup(of: FileOutcome.self) { group in
        // Seed the group up to the concurrency cap…
        for _ in 0..<maxConcurrent {
          guard let next = iterator.next() else { break }
          group.addTask { await self.runOne(next) }
        }
        // …then refill one task for every completion until inputs are exhausted.
        for await outcome in group {
          outcomes.append(outcome)
          if let next = iterator.next() {
            group.addTask { await self.runOne(next) }
          }
        }
      }

      // Phase 3: write outputs and surface diagnostics. Successes are always
      // written, even when other files in the batch failed (Tuist-analog batch
      // semantics).
      var failed = 0
      for outcome in outcomes {
        let relative = outcome.input.path.dropFirst(inputURL.path.count + 1)
        let destination = outputURL.appendingPathComponent(String(relative))

        switch outcome.result {
        case .failure(let error):
          failed += 1
          FileHandle.standardError.write(Data("\(outcome.input.path): \(error)\n".utf8))
        case .success(let processResult):
          // Per-input stderr is fenced with a header so the batch log stays
          // readable when several files emit diagnostics.
          if !processResult.stderr.isEmpty {
            FileHandle.standardError.write(Data("---- \(outcome.input.path) ----\n".utf8))
            FileHandle.standardError.write(Data(processResult.stderr.utf8))
          }
          if processResult.exitCode != 0 {
            failed += 1
            continue
          }
          do {
            try FileManager.default.createDirectory(
              at: destination.deletingLastPathComponent(),
              withIntermediateDirectories: true
            )
            try processResult.stdout.write(to: destination)
          } catch {
            failed += 1
            FileHandle.standardError.write(Data("\(outcome.input.path): \(error)\n".utf8))
          }
        }
      }

      // Phase 4: one-line batch summary + overall exit code.
      FileHandle.standardError.write(
        Data(
          "skit: \(outcomes.count - failed)/\(outcomes.count) succeeded\n".utf8
        ))

      return failed == 0 ? 0 : 1
    }

    /// `processFile` adapter that catches errors into the `FileOutcome` result
    /// so a single failure doesn't tear down the surrounding `TaskGroup`.
    private func runOne(_ input: URL) async -> FileOutcome {
      do {
        let result = try await processFile(inputPath: input.path)
        return FileOutcome(input: input, result: .success(result))
      } catch {
        return FileOutcome(input: input, result: .failure(error))
      }
    }

    /// Returns every `.swift` file under `inputDir` (recursive), sorted, with
    /// hidden files and files prefixed by `_` removed. Sorted output keeps
    /// batch behaviour deterministic across runs.
    private static func collectInputs(at inputDir: URL) throws -> [URL] {
      guard
        let enumerator = FileManager.default.enumerator(
          at: inputDir,
          includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
          options: [.skipsHiddenFiles]
        )
      else {
        throw CLIError(message: "could not enumerate \(inputDir.path)")
      }

      var result: [URL] = []
      for case let url as URL in enumerator {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
        // Directories aren't outputs.
        if values.isDirectory == true { continue }
        // Filter for `.swift` regular files, skipping the `_`-prefixed
        // convention for "not an input" sources.
        guard values.isRegularFile == true else { continue }
        guard url.pathExtension == "swift" else { continue }
        guard !url.lastPathComponent.hasPrefix("_") else { continue }
        result.append(url.standardizedFileURL)
      }
      return result.sorted { $0.path < $1.path }
    }

    // MARK: - Per-file work

    /// The per-input render pipeline: load source → consult the output cache →
    /// (on miss) wrap → spawn `swift` → rewrite diagnostics → store the result
    /// in the cache. The temp wrapper file is created in a per-run tmp dir and
    /// torn down by `defer` whether the spawn succeeded or not.
    private func processFile(inputPath: String) async throws -> ProcessResult {
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

    /// Bounded output capacity for the spawned `swift` (16 MiB). Generated DSL
    /// output above this size is exotic; if we ever hit it we'll see a clear
    /// SubprocessError rather than a silent truncation.
    private static let stdoutLimitBytes: Int = 16 * 1_024 * 1_024
    private static let stderrLimitBytes: Int = 1 * 1_024 * 1_024

    /// Spawns `swift` (script-mode interpreter) on the wrapped input file.
    /// When `timeoutSeconds > 0` the spawn races a sleep task in a throwing
    /// task group; the loser is cancelled. On timeout, returns exit 124 with
    /// a one-line stderr message — matching POSIX `timeout(1)`'s convention.
    private func runSwift(wrappedPath: String) async throws -> ProcessResult {
      // Build the `swift` invocation (executable + link/include/rpath flags).
      let configuration = Subprocess.Configuration.swift(libPath: libPath, wrappedPath: wrappedPath)

      // The actual subprocess call, wrapped in a closure so the task-group race
      // below can hold a single Sendable reference to it.
      let invocation: @Sendable () async throws -> SwiftRunOutcome = {
        let record = try await Subprocess.run(
          configuration,
          output: .string(limit: Self.stdoutLimitBytes),
          error: .string(limit: Self.stderrLimitBytes)
        )
        return .completed(
          exitCode: Self.exitCode(from: record.terminationStatus),
          stdout: Data((record.standardOutput ?? "").utf8),
          stderr: record.standardError ?? ""
        )
      }

      // Race the invocation against a sleep watchdog; whichever finishes first
      // wins, the other is cancelled. `timeoutSeconds <= 0` opts out of the
      // race entirely (useful for debugging genuinely long codegen).
      let outcome: SwiftRunOutcome
      if timeoutSeconds <= 0 {
        outcome = try await invocation()
      } else {
        outcome =
          try await Task.timeout(.seconds(timeoutSeconds), operation: invocation)
          ?? .timedOut
      }

      // Normalize both outcomes into a single ProcessResult shape.
      switch outcome {
      case .completed(let exitCode, let stdout, let stderr):
        return ProcessResult(exitCode: exitCode, stdout: stdout, stderr: stderr)
      case .timedOut:
        return ProcessResult(
          exitCode: Self.timeoutExitCode,
          stdout: Data(),
          stderr: "skit: timed out after \(timeoutSeconds)s\n"
        )
      }
    }

    /// Collapses Subprocess's `TerminationStatus` into a single Int32 exit code,
    /// using the shell convention (128 + signal number) for signalled deaths.
    private static func exitCode(from status: TerminationStatus) -> Int32 {
      switch status {
      case .exited(let code):
        return Int32(truncatingIfNeeded: code)
      #if !os(Windows)
        case .signaled(let signal):
          // Match shell convention: 128 + signal number.
          return 128 + Int32(truncatingIfNeeded: signal)
      #endif
      }
    }
  }

#endif
