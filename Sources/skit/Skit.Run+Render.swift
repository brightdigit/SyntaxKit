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

import ArgumentParser
import Foundation
import SyntaxKit

#if canImport(Subprocess)

  import Subprocess

  extension Skit.Run {
    /// Classifies `input` and dispatches to the matching `Runner` SDK method.
    /// The SDK layer is silent — this function (and its helpers) own all
    /// stdout/stderr presentation, file IO for single-file mode, and the
    /// mapping from `RunError`/batch failures to the process exit behaviour
    /// the CLI promises: `ValidationError` (exit 64) for usage errors,
    /// `ExitCode` for render/batch failures, and rethrow for anything
    /// unexpected (ArgumentParser prints + exit 1).
    internal func render(using runner: Runner, input: String, output: String?) async throws {
      let resolved: RunInput
      do {
        resolved = try RunInput.resolve(input: input, output: output)
      } catch .invalidInput(let message) {
        throw ValidationError(message)
      } catch {
        // RunInput.resolve only throws .invalidInput; defensive.
        throw ExitCode(1)
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
    ) async throws {
      let rendered: SingleFileRender
      do {
        rendered = try await runner.renderFile(input: input)
      } catch .invalidInput(let message) {
        throw ValidationError(message)
      } catch .renderFailed(let exitCode, let stderr) {
        if !stderr.isEmpty {
          FileHandle.standardError.write(Data(stderr.utf8))
        }
        throw ExitCode(exitCode)
      } catch .unexpected(let underlying) {
        throw underlying
      }

      if !rendered.stderr.isEmpty {
        FileHandle.standardError.write(Data(rendered.stderr.utf8))
      }
      if let output {
        try rendered.stdout.write(to: URL(fileURLWithPath: output))
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
    ) async throws {
      let result: DirectoryRender
      do {
        result = try await runner.renderDirectory(inputDir: input, outputDir: output)
      } catch .invalidInput(let message) {
        throw ValidationError(message)
      } catch .unexpected(let underlying) {
        // `renderDirectory` only wraps directory-walk failures in `.unexpected`;
        // surface the original "failed to walk" framing the CLI used to print
        // before the SDK split.
        FileHandle.standardError.write(
          Data("skit: failed to walk \(input): \(underlying)\n".utf8)
        )
        throw ExitCode(1)
      } catch {
        // renderDirectory does not throw .renderFailed — that's a per-file
        // outcome. Defensive.
        throw ExitCode(1)
      }

      if result.outcomes.isEmpty {
        FileHandle.standardError.write(Data("skit: no .swift inputs under \(input)\n".utf8))
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
          "skit: \(result.outcomes.count - result.failureCount)/\(result.outcomes.count) succeeded\n"
            .utf8
        )
      )

      if result.failureCount > 0 {
        throw ExitCode(1)
      }
    }

    /// Verbatim `swift --version` output, or nil on spawn failure. Capped at 4 KiB.
    internal func captureSwiftVersion() async -> String? {
      let result = try? await Subprocess.run(
        .name("swift"),
        arguments: ["--version"],
        output: .string(limit: 4_096),
        error: .discarded
      )
      return result?.standardOutput
    }

    /// Human-readable error emitted when the bundle's recorded `swift --version`
    /// differs from the local one, explaining why and how to recover.
    internal func toolchainMismatchMessage(bundle: String, local: String) -> String {
      """
      skit: toolchain mismatch
        bundle: \(bundle)
        local:  \(local)
      The bundle's libSyntaxKit was built against a different `swift` than the
      one on your PATH. Swift swiftmodules aren't reliably compatible across
      versions, so spawning `swift` would fail with a cryptic module-version
      diagnostic.

      Rebuild the bundle with:
        Scripts/build-skit-release.sh
      Or pass --no-toolchain-check to try anyway.

      """
    }
  }

#endif
