//
//  RenderTaskResult.swift
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

/// Payload the per-input render `TaskGroup` yields back to `renderDirectory`.
/// Failures are captured (not thrown) so a single bad input doesn't tear down
/// the group; `processFile`'s heterogeneous Foundation/Subprocess throws are
/// normalized into `RunError` (typically `.unexpected`) by `runOne`.
/// `internal` so `FileManager.writeOutput` (in `FileManager+Execution.swift`)
/// can consume it.
internal struct RenderTaskResult: Sendable {
  /// Bundles a successful render's bytes with the destination they should be
  /// written to. Nested because it's only ever produced by `writeOutput` to
  /// hand off to its caller-supplied writer closure.
  internal struct OutputDestination: Sendable {
    internal let output: Data
    internal let destination: URL
  }

  internal let input: URL
  internal let result: Result<ProcessResult, RunError>

  internal func writeOutput(
    to destination: URL,
    toolchain: ToolchainVerification,
    using writeOutputDestination: (OutputDestination) throws -> Void
  ) throws(RunError) {
    let result = try self.result.get()

    guard result.exitCode == 0 else {
      throw .renderFailed(
        exitCode: result.exitCode,
        stderr: result.stderr,
        toolchain: toolchain
      )
    }

    let outputDestination = OutputDestination(output: result.stdout, destination: destination)

    do {
      try writeOutputDestination(outputDestination)
    } catch {
      throw .unexpected(error)
    }
  }
}
