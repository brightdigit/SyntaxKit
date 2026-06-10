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
  public func renderDirectory(
    inputDir: String,
    outputDir: String
  ) async throws(RunError) -> DirectoryRender {
    let inputURL = URL(fileURLWithPath: inputDir).standardizedFileURL
    let outputURL = URL(fileURLWithPath: outputDir).standardizedFileURL

    // Phase 1: enumerate inputs. A walk failure is a bulk failure: there's
    // nothing per-file to report, so it surfaces as a typed throw. The
    // collect-specific error is folded into `RunError.unexpected` — the bulk
    // channel the caller already presents.
    let inputs: [URL]
    do {
      inputs = try FileManager.default.collectInputs(at: inputURL)
    } catch {
      throw RunError.unexpected(error)
    }
    guard !inputs.isEmpty else {
      return DirectoryRender(outcomes: [])
    }

    // Phase 2: render every input with bounded concurrency.
    let renderResults = await processInputs(inputs)

    // Phase 3: write successes and capture a per-input outcome for each.
    let outcomes = renderResults.map {
      FileManager.default.writeOutput(
        for: $0,
        inputBase: inputURL,
        outputBase: outputURL,
        toolchain: toolchainVerification
      )
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

/// Payload the per-input render `TaskGroup` yields back to `renderDirectory`.
/// Failures are captured (not thrown) so a single bad input doesn't tear down
/// the group; `processFile`'s heterogeneous Foundation/Subprocess throws are
/// normalized into `RunError` (typically `.unexpected`) by `runOne`.
/// `internal` so `FileManager.writeOutput` (in `FileManager+Execution.swift`)
/// can consume it.
internal struct RenderTaskResult: Sendable {
  internal let input: URL
  internal let result: Result<ProcessResult, RunError>
}
