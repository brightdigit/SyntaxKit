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

  /// Reads `input`, renders it via the filesystem-free `Runner.render(source:)`,
  /// prints any compiler stderr, and writes the rendered Swift source either to
  /// `output` or to stdout. The runner reads and writes nothing — that's the
  /// CLI's job.
  private static func renderSingle(
    runner: Runner,
    input: String,
    output: String?
  ) async throws(RunCommandError) {
    let inputURL = URL(fileURLWithPath: input).standardizedFileURL
    let source: String
    do {
      source = try String(contentsOf: inputURL, encoding: .utf8)
    } catch {
      throw RunCommandError.unexpected(error)
    }

    let rendered: SingleFileRender
    do {
      rendered = try await runner.render(source: source, originalPath: inputURL.path)
    } catch {
      // `error` is typed `RunError` (render is `throws(RunError)`); the
      // initializer's switch is exhaustive, so this single catch is total.
      throw RunCommandError(renderFileError: error)
    }

    try emit(rendered, to: output)
  }

  /// Prints any diagnostics, then writes the rendered source to `output` (or
  /// stdout when `output` is nil). A write failure has no diagnostic of its own,
  /// so the underlying error is surfaced (ArgumentParser prints it, exit 1).
  private static func emit(
    _ rendered: SingleFileRender,
    to output: String?
  ) throws(RunCommandError) {
    if !rendered.stderr.isEmpty {
      FileHandle.standardError.write(Data(rendered.stderr.utf8))
    }
    guard let output else {
      FileHandle.standardOutput.write(rendered.stdout)
      return
    }
    do {
      try rendered.stdout.write(to: URL(fileURLWithPath: output))
    } catch {
      throw RunCommandError.unexpected(error)
    }
  }
}
