//
//  Runner+Directory.swift
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

extension Runner {
  /// Walks `inputDir` for `.swift` inputs, processes them concurrently (up to
  /// the active core count), and mirrors successfully-rendered outputs into
  /// `outputDir`. A failure on one input does not abort the batch — successful
  /// peers are still written. Returns a `DirectoryRender` with per-input
  /// outcomes; the caller inspects `failureCount` (and per-outcome stderr) to
  /// decide presentation.
  ///
  /// Throws `RunError.unexpected` only for bulk failures the SDK can't
  /// recover from (e.g. the input directory can't be enumerated). An empty
  /// input set is *not* an error — the result simply has no outcomes.
  package func renderDirectory(
    inputDir: String,
    outputDir: String
  ) async throws(RunError) -> DirectoryRender {
    let inputURL = URL(fileURLWithPath: inputDir).standardizedFileURL
    let outputURL = URL(fileURLWithPath: outputDir).standardizedFileURL

    // Phase 1: enumerate inputs. A walk failure is a bulk failure: there's
    // nothing per-file to report, so it surfaces as a typed throw.
    let inputs = try FileManager.default.collectInputs(at: inputURL)
    guard !inputs.isEmpty else {
      return DirectoryRender(outcomes: [])
    }

    // Phase 2: render every input with bounded concurrency.
    let renderResults = await processInputs(inputs)

    // Phase 3: write successes and capture a per-input outcome for each.
    let outcomes = renderResults.map {
      writeOutput(for: $0, inputBase: inputURL, outputBase: outputURL)
    }

    return DirectoryRender(outcomes: outcomes)
  }

  /// Renders every input through `runOne` with bounded concurrency. The cap is
  /// the active core count so a 200-file batch doesn't fork 200 simultaneous
  /// `swift` processes: the group is seeded up to the cap, then refilled one
  /// task per completion until the inputs are exhausted.
  private func processInputs(_ inputs: [URL]) async -> [RenderTaskResult] {
    let maxConcurrent = max(1, ProcessInfo.processInfo.activeProcessorCount)

    var renderResults: [RenderTaskResult] = []
    renderResults.reserveCapacity(inputs.count)
    var iterator = inputs.makeIterator()

    await withTaskGroup(of: RenderTaskResult.self) { group in
      // Seed the group up to the concurrency cap…
      for _ in 0..<maxConcurrent {
        guard let next = iterator.next() else { break }
        group.addTask { await self.runOne(next) }
      }
      // …then refill one task for every completion until inputs are exhausted.
      for await outcome in group {
        renderResults.append(outcome)
        if let next = iterator.next() {
          group.addTask { await self.runOne(next) }
        }
      }
    }

    return renderResults
  }

  /// Builds the `FileOutcome` for one render result, writing a successful
  /// render's stdout to its mirrored destination under `outputBase`. The write
  /// side effect lives here; failures (a non-zero render exit, or a write
  /// error) are captured into the returned outcome rather than thrown, so a
  /// failing peer doesn't prevent successful files in the batch from being
  /// written (Tuist-analog batch semantics). No diagnostics are printed here;
  /// the caller does that.
  private func writeOutput(
    for result: RenderTaskResult,
    inputBase: URL,
    outputBase: URL
  ) -> DirectoryRender.FileOutcome {
    let relative = result.input.path.dropFirst(inputBase.path.count + 1)
    let destination = outputBase.appendingPathComponent(String(relative))

    switch result.result {
    case .failure(let error):
      return DirectoryRender.FileOutcome(
        input: result.input,
        destination: destination,
        stderr: "",
        result: .failure(error)
      )
    case .success(let processResult):
      if processResult.exitCode != 0 {
        return DirectoryRender.FileOutcome(
          input: result.input,
          destination: destination,
          stderr: processResult.stderr,
          result: .failure(
            .renderFailed(exitCode: processResult.exitCode, stderr: processResult.stderr)
          )
        )
      }
      do {
        try FileManager.default.createDirectory(
          at: destination.deletingLastPathComponent(),
          withIntermediateDirectories: true
        )
        try processResult.stdout.write(to: destination)
        return DirectoryRender.FileOutcome(
          input: result.input,
          destination: destination,
          stderr: processResult.stderr,
          result: .success(())
        )
      } catch {
        return DirectoryRender.FileOutcome(
          input: result.input,
          destination: destination,
          stderr: processResult.stderr,
          result: .failure(.unexpected(error))
        )
      }
    }
  }

  /// `processFile` adapter that catches errors into the `RenderTaskResult`
  /// so a single failure doesn't tear down the surrounding `TaskGroup`.
  /// `processFile`'s heterogeneous Foundation/Subprocess throws are wrapped
  /// in `RunError.unexpected` here so the rest of the pipeline sees a single
  /// typed error.
  private func runOne(_ input: URL) async -> RenderTaskResult {
    do {
      let result = try await processFile(inputPath: input.path)
      return RenderTaskResult(input: input, result: .success(result))
    } catch let error as RunError {
      return RenderTaskResult(input: input, result: .failure(error))
    } catch {
      return RenderTaskResult(input: input, result: .failure(.unexpected(error)))
    }
  }
}

extension FileManager {
  /// Returns every `.swift` file under `inputDir` (recursive), sorted, with
  /// hidden files and files prefixed by `_` removed. Sorted output keeps
  /// batch behaviour deterministic across runs.
  ///
  /// Throws `RunError.unexpected` when the directory can't be enumerated or a
  /// file's resource values can't be read — both are bulk failures with
  /// nothing per-file to report.
  internal func collectInputs(at inputDir: URL) throws(RunError) -> [URL] {
    guard
      let enumerator = enumerator(
        at: inputDir,
        includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
    else {
      throw RunError.unexpected(CLIError(message: "could not enumerate \(inputDir.path)"))
    }

    var result: [URL] = []
    for case let url as URL in enumerator {
      let values: URLResourceValues
      do {
        values = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
      } catch {
        throw RunError.unexpected(error)
      }
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
}

/// Payload the per-input render `TaskGroup` yields back to `renderDirectory`.
/// Failures are captured (not thrown) so a single bad input doesn't tear down
/// the group; `processFile`'s heterogeneous Foundation/Subprocess throws are
/// normalized into `RunError` (typically `.unexpected`) by `runOne`.
private struct RenderTaskResult: Sendable {
  let input: URL
  let result: Result<ProcessResult, RunError>
}
