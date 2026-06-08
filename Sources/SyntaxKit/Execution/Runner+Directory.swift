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
    let inputs: [URL]
    do {
      inputs = try Self.collectInputs(at: inputURL)
    } catch {
      throw RunError.unexpected(error)
    }

    if inputs.isEmpty {
      return DirectoryRender(outcomes: [])
    }

    // Phase 2: bounded-concurrency processing. Cap is the active core count
    // so a 200-file batch doesn't fork 200 simultaneous `swift` processes.
    let maxConcurrent = max(1, ProcessInfo.processInfo.activeProcessorCount)

    var renderResults: [RenderTaskResult] = []
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

    // Phase 3: write outputs and capture per-input outcomes. Successes are
    // written even when other files in the batch failed (Tuist-analog batch
    // semantics). No diagnostics are printed here; the caller does that.
    var outcomes: [DirectoryRender.FileOutcome] = []
    outcomes.reserveCapacity(renderResults.count)
    for outcome in renderResults {
      let relative = outcome.input.path.dropFirst(inputURL.path.count + 1)
      let destination = outputURL.appendingPathComponent(String(relative))

      switch outcome.result {
      case .failure(let error):
        outcomes.append(
          DirectoryRender.FileOutcome(
            input: outcome.input,
            destination: destination,
            stderr: "",
            result: .failure(error)
          )
        )
      case .success(let processResult):
        if processResult.exitCode != 0 {
          outcomes.append(
            DirectoryRender.FileOutcome(
              input: outcome.input,
              destination: destination,
              stderr: processResult.stderr,
              result: .failure(
                .renderFailed(exitCode: processResult.exitCode, stderr: processResult.stderr)
              )
            )
          )
          continue
        }
        do {
          try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
          )
          try processResult.stdout.write(to: destination)
          outcomes.append(
            DirectoryRender.FileOutcome(
              input: outcome.input,
              destination: destination,
              stderr: processResult.stderr,
              result: .success(())
            )
          )
        } catch {
          outcomes.append(
            DirectoryRender.FileOutcome(
              input: outcome.input,
              destination: destination,
              stderr: processResult.stderr,
              result: .failure(.unexpected(error))
            )
          )
        }
      }
    }

    return DirectoryRender(outcomes: outcomes)
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
}

/// Payload the per-input render `TaskGroup` yields back to `renderDirectory`.
/// Failures are captured (not thrown) so a single bad input doesn't tear down
/// the group; `processFile`'s heterogeneous Foundation/Subprocess throws are
/// normalized into `RunError` (typically `.unexpected`) by `runOne`.
private struct RenderTaskResult: Sendable {
  let input: URL
  let result: Result<ProcessResult, RunError>
}
