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
  /// Renders a batch of in-memory inputs concurrently (up to the active core
  /// count) and returns a per-input `FileOutcome` carrying the rendered
  /// `stdout`, diagnostics, and any `RunError`. The SDK reads nothing and
  /// writes nothing — the caller supplies the sources (e.g. via
  /// `FileManager.collectInputs` + reads) and writes each successful
  /// `stdout` wherever it likes (e.g. by rerooting `outcome.input`). A failure
  /// on one input does not affect its peers; inspect `failureCount` (and
  /// per-outcome `stderr`) to decide presentation. An empty input set yields an
  /// empty array.
  public func render(sources: [RenderInput]) async -> [FileOutcome] {
    guard !sources.isEmpty else {
      return []
    }

    // Render every input with bounded concurrency, then fold each raw result
    // into the public per-input outcome.
    let renderResults = await processInputs(sources)
    return renderResults.map(outcome(for:))
  }

  /// Folds one raw `RenderTaskResult` into a public `FileOutcome`: a zero-exit
  /// render yields its `stdout` with `result == nil`; a non-zero exit becomes
  /// `.renderFailed` (carrying the session toolchain); a captured throw is
  /// surfaced as-is. No file IO — writing is the caller's job.
  private func outcome(for taskResult: RenderTaskResult) -> FileOutcome {
    switch taskResult.result {
    case .success(let process) where process.exitCode == 0:
      return FileOutcome(
        input: taskResult.input,
        stdout: process.stdout,
        stderr: process.stderr,
        result: nil
      )
    case .success(let process):
      return FileOutcome(
        input: taskResult.input,
        stdout: Data(),
        stderr: process.stderr,
        result: .renderFailed(
          exitCode: process.exitCode,
          stderr: process.stderr,
          toolchain: toolchainVerification
        )
      )
    case .failure(let error):
      return FileOutcome(input: taskResult.input, stdout: Data(), stderr: "", result: error)
    }
  }

  /// Renders every input through `runOne` with bounded concurrency. The cap is
  /// the active core count so a 200-file batch doesn't fork 200 simultaneous
  /// `swift` processes: the group is seeded up to the cap, then refilled one
  /// task per completion until the inputs are exhausted.
  private func processInputs(_ inputs: [RenderInput]) async -> [RenderTaskResult] {
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
  private func runOne(_ input: RenderInput) async -> RenderTaskResult {
    do {
      let result = try await processFile(source: input.source, originalPath: input.url.path)
      return RenderTaskResult(input: input.url, result: .success(result))
    } catch let error as RunError {
      return RenderTaskResult(input: input.url, result: .failure(error))
    } catch {
      return RenderTaskResult(input: input.url, result: .failure(.unexpected(error)))
    }
  }
}
