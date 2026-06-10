//
//  Render.swift
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

/// Render-side IO for the `skit run` subcommand: classifies the input, calls
/// the silent `Runner` SDK, and owns all stdout/stderr presentation and file
/// writes. Hosted in an `enum` namespace because none of these helpers use
/// instance state from `Skit.Run` — extracted from `Skit.Run` so the
/// subcommand struct stays focused on argument parsing.
internal enum Render {
  /// Classifies `input` and dispatches to the matching `Runner` SDK method.
  /// The SDK layer is silent — this function (and its helpers) own all
  /// stdout/stderr presentation and file IO, and translate `RunError`/batch
  /// failures into the typed `RunCommandError` that `Skit.Run.run()` maps to
  /// a process exit. Success-path output is still written here.
  internal static func render(using runner: Runner, input: String, output: String?)
    async throws(RunCommandError)
  {
    let resolved: RunInput
    do {
      resolved = try RunInput.resolve(input: input, output: output)
    } catch .invalidInput(let message) {
      throw RunCommandError.usage(message)
    } catch {
      // RunInput.resolve only throws .invalidInput; defensive.
      throw RunCommandError.failed
    }

    switch resolved {
    case .singleFile(let inputPath, let outputPath):
      try await renderSingle(runner: runner, input: inputPath, output: outputPath)
    case .directory(let inputDir, let outputDir):
      try await renderBatch(runner: runner, input: inputDir, output: outputDir)
    }
  }

  /// Renders one input via `Runner.renderFile`, prints any compiler stderr,
  /// and writes the rendered Swift source either to `outputPath` or to
  /// stdout. The runner itself does none of that — that's the CLI's job.
  private static func renderSingle(
    runner: Runner,
    input: String,
    output: String?
  ) async throws(RunCommandError) {
    let rendered: SingleFileRender
    do {
      rendered = try await runner.renderFile(input: input)
    } catch {
      // `error` is typed `RunError` (renderFile is `throws(RunError)`); the
      // initializer's switch is exhaustive, so this single catch is total.
      throw RunCommandError(renderFileError: error)
    }

    if !rendered.stderr.isEmpty {
      FileHandle.standardError.write(Data(rendered.stderr.utf8))
    }
    if let output {
      do {
        try rendered.stdout.write(to: URL(fileURLWithPath: output))
      } catch {
        // A write failure has no diagnostic of its own; surface the underlying
        // error (ArgumentParser prints it, exit 1).
        throw RunCommandError.unexpected(error)
      }
    } else {
      FileHandle.standardOutput.write(rendered.stdout)
    }
  }

  /// Renders a directory batch via `Runner.renderDirectory`, prints per-input
  /// diagnostics (fenced when several files emit them), surfaces non-render
  /// failures, prints a one-line summary, and maps any failures to
  /// `ExitCode(1)` — Tuist-analog batch semantics.
  private static func renderBatch(
    runner: Runner,
    input: String,
    output: String
  ) async throws(RunCommandError) {
    let outcomes: [FileOutcome]
    do {
      outcomes = try await runner.renderDirectory(inputDir: input, outputDir: output)
    } catch {
      // `error` is typed `RunError` (renderDirectory is `throws(RunError)`);
      // the initializer's switch is exhaustive, so this single catch is total.
      throw RunCommandError(renderDirectoryError: error, input: input)
    }

    if outcomes.isEmpty {
      FileHandle.standardError.write(
        Data("\(Skit.Run.messagePrefix)no .swift inputs under \(input)\n".utf8)
      )
      return
    }

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
}
