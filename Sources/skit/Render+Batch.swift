//
//  Render+Batch.swift
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
import SyntaxKit

extension Render {
  /// Collects a directory's `.swift` inputs, reads them, renders them via the
  /// filesystem-free `Runner.render(sources:)`, mirrors each rendered output
  /// into `output`, prints per-input diagnostics (fenced when several files
  /// emit them), prints a one-line summary, and maps any failures to
  /// `ExitCode(1)` — Tuist-analog batch semantics.
  internal static func renderBatch(
    runner: Runner,
    input: String,
    output: String
  ) async throws(RunCommandError) {
    let inputURL = URL(fileURLWithPath: input).standardizedFileURL
    let outputURL = URL(fileURLWithPath: output).standardizedFileURL

    let inputs: [URL]
    do {
      inputs = try FileManager.default.collectInputs(at: inputURL)
    } catch {
      throw RunCommandError(collectInputsError: error, input: input)
    }

    if inputs.isEmpty {
      FileHandle.standardError.write(
        Data("\(Skit.Run.messagePrefix)no .swift inputs under \(input)\n".utf8)
      )
      return
    }

    // Read inputs into memory (read failures become per-file outcomes so a bad
    // input doesn't abort the batch), render in-memory, then mirror each
    // successful render into the output tree.
    let (sources, readFailures) = loadSources(inputs)
    let rendered = await runner.render(sources: sources)
    let written = rendered.map { writeRendered($0, inputBase: inputURL, outputBase: outputURL) }
    let outcomes = readFailures + written

    reportOutcomeDiagnostics(outcomes)

    FileHandle.standardError.write(
      Data(
        ("\(Skit.Run.messagePrefix)\(outcomes.count - outcomes.failureCount)"
          + "/\(outcomes.count) succeeded\n").utf8
      )
    )

    if outcomes.failureCount > 0 {
      // Some inputs failed; if the toolchain couldn't be verified, hint once
      // that a Swift-version mismatch may be behind the build errors above.
      if let hint = RunCommandError.toolchainHint(runner.toolchainVerification) {
        FileHandle.standardError.write(Data(hint.utf8))
      }
      throw RunCommandError.failed
    }
  }

  /// Prints per-input diagnostics for a batch: each file's compiler stderr
  /// (fenced with a `---- path ----` header), then for any non-`.renderFailed`
  /// failure (whose stderr was just surfaced) a one-line `path: error`. Spawn/
  /// write failures carry their diagnostic in the error itself.
  private static func reportOutcomeDiagnostics(_ outcomes: [FileOutcome]) {
    for outcome in outcomes {
      if !outcome.stderr.isEmpty {
        FileHandle.standardError.write(Data("---- \(outcome.input.path) ----\n".utf8))
        FileHandle.standardError.write(Data(outcome.stderr.utf8))
      }
      // .renderFailed already had its stderr surfaced above. Other failures
      // (process spawn, write) carry the diagnostic in the error itself.
      if let error = outcome.result {
        if case .renderFailed = error {
          continue
        }
        FileHandle.standardError.write(Data("\(outcome.input.path): \(error)\n".utf8))
      }
    }
  }

  /// Reads every input into a `RenderInput`. A read failure does not abort the
  /// batch — it becomes a per-file `.unexpected` `FileOutcome`, returned
  /// alongside the successfully-loaded sources.
  private static func loadSources(
    _ inputs: [URL]
  ) -> (sources: [RenderInput], failures: [FileOutcome]) {
    var sources: [RenderInput] = []
    var failures: [FileOutcome] = []
    for url in inputs {
      do {
        let source = try String(contentsOf: url, encoding: .utf8)
        sources.append(RenderInput(url: url, source: source))
      } catch {
        failures.append(
          FileOutcome(input: url, stdout: Data(), stderr: "", result: .unexpected(error))
        )
      }
    }
    return (sources, failures)
  }

  /// Mirrors a successful render's `stdout` to its destination under
  /// `outputBase`, folding any write error into the returned outcome. Already-
  /// failed outcomes pass through untouched.
  private static func writeRendered(
    _ outcome: FileOutcome,
    inputBase: URL,
    outputBase: URL
  ) -> FileOutcome {
    guard outcome.result == nil else {
      return outcome
    }
    let destination = outcome.input.rerooted(from: inputBase, onto: outputBase)
    do {
      try FileManager.default.writeData(outcome.stdout, to: destination)
      return outcome
    } catch {
      return FileOutcome(
        input: outcome.input,
        stdout: outcome.stdout,
        stderr: outcome.stderr,
        result: .unexpected(error)
      )
    }
  }
}
