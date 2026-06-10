//
//  Skit.Run+Render.swift
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

extension Skit.Run {
  /// Classifies `input` and dispatches to the matching `Runner` SDK method.
  /// The SDK layer is silent — this function (and its helpers) own all
  /// stdout/stderr presentation and file IO, and translate `RunError`/batch
  /// failures into the typed `CommandError` that `run()` maps to a process
  /// exit. Success-path output is still written here.
  internal func render(using runner: Runner, input: String, output: String?)
    async throws(CommandError)
  {
    let resolved: RunInput
    do {
      resolved = try RunInput.resolve(input: input, output: output)
    } catch .invalidInput(let message) {
      throw CommandError.usage(message)
    } catch {
      // RunInput.resolve only throws .invalidInput; defensive.
      throw CommandError.failed
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
  fileprivate func renderSingle(
    runner: Runner,
    input: String,
    output: String?
  ) async throws(CommandError) {
    let rendered: SingleFileRender
    do {
      rendered = try await runner.renderFile(input: input)
    } catch {
      // `error` is typed `RunError` (renderFile is `throws(RunError)`); the
      // switch is exhaustive, so this single catch is both total (satisfies
      // `throws(CommandError)`) and free of an unreachable clause.
      switch error {
      case .invalidInput(let message):
        throw CommandError.usage(message)
      case .renderFailed(let exitCode, let stderr, let toolchain):
        throw CommandError.renderFailed(exitCode: exitCode, stderr: stderr, toolchain: toolchain)
      case .unexpected(let underlying):
        throw CommandError.unexpected(underlying)
      }
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
        throw CommandError.unexpected(error)
      }
    } else {
      FileHandle.standardOutput.write(rendered.stdout)
    }
  }

  /// Renders a directory batch via `Runner.renderDirectory`, prints per-input
  /// diagnostics (fenced when several files emit them), surfaces non-render
  /// failures, prints a one-line summary, and maps any failures to
  /// `ExitCode(1)` — Tuist-analog batch semantics.
  fileprivate func renderBatch(
    runner: Runner,
    input: String,
    output: String
  ) async throws(CommandError) {
    let result: DirectoryRender
    do {
      result = try await runner.renderDirectory(inputDir: input, outputDir: output)
    } catch .invalidInput(let message) {
      throw CommandError.usage(message)
    } catch .unexpected(let underlying) {
      // `renderDirectory` only wraps directory-walk failures in `.unexpected`;
      // `CommandError.directoryWalkFailed` carries the original "failed to
      // walk" framing the CLI prints.
      throw CommandError.directoryWalkFailed(input: input, underlying: underlying)
    } catch {
      // renderDirectory does not throw .renderFailed — that's a per-file
      // outcome. Defensive.
      throw CommandError.failed
    }

    if result.outcomes.isEmpty {
      FileHandle.standardError.write(
        Data("\(Self.messagePrefix)no .swift inputs under \(input)\n".utf8))
      return
    }

    for outcome in result.outcomes {
      if !outcome.stderr.isEmpty {
        FileHandle.standardError.write(Data("---- \(outcome.input.path) ----\n".utf8))
        FileHandle.standardError.write(Data(outcome.stderr.utf8))
      }
      // .renderFailed already had its stderr surfaced above. Other failures
      // (process spawn, write) carry the diagnostic in the error itself.
      if let error = outcome.result {
        if let runError = error as? RunError, case .renderFailed = runError {
          continue
        }
        FileHandle.standardError.write(Data("\(outcome.input.path): \(error)\n".utf8))
      }
    }

    FileHandle.standardError.write(
      Data(
        ("\(Self.messagePrefix)\(result.outcomes.count - result.failureCount)"
          + "/\(result.outcomes.count) succeeded\n").utf8
      )
    )

    if result.failureCount > 0 {
      // Some inputs failed; if the toolchain couldn't be verified, hint once
      // that a Swift-version mismatch may be behind the build errors above.
      if let hint = CommandError.toolchainHint(runner.toolchainVerification) {
        FileHandle.standardError.write(Data(hint.utf8))
      }
      throw CommandError.failed
    }
  }
}
