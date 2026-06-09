//
//  DirectoryRender.swift
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

public import Foundation

/// Result of `Runner.renderDirectory`. Successful rendered outputs are
/// written into the mirrored output tree as the batch progresses; this
/// value is the post-batch summary the caller inspects to decide
/// presentation (logging, exit code, etc.). Per-input failures are
/// captured here, not thrown, so a single bad input doesn't tear the
/// batch down.
public struct DirectoryRender: Sendable {
  /// Per-input result. `stderr` carries the (possibly path-rewritten)
  /// diagnostics from the spawned `swift`; it may be present whether or not
  /// the input succeeded (e.g. a successful render that emitted warnings).
  /// `result` is `nil` when the rendered output was written to its mirrored
  /// destination, and carries the error when the input could not be rendered
  /// or its output could not be written (typically a `RunError`).
  public struct FileOutcome: Sendable {
    /// The input file this outcome describes.
    public let input: URL
    /// The (possibly path-rewritten) `swift` diagnostics for this input.
    public let stderr: String
    /// `nil` when the output was written; the error otherwise.
    public let result: (any Error)?

    /// Creates an outcome for one rendered (or failed) input.
    public init(
      input: URL,
      stderr: String,
      result: (any Error)?
    ) {
      self.input = input
      self.stderr = stderr
      self.result = result
    }
  }

  /// Per-input outcomes, in the order the batch produced them.
  public let outcomes: [FileOutcome]

  /// Creates a batch summary from the collected per-input outcomes.
  public init(outcomes: [FileOutcome]) {
    self.outcomes = outcomes
  }

  /// Number of inputs whose `result` is `.failure` — the signal the caller
  /// uses to map a partially-failed batch to a non-zero exit (or whatever
  /// failure semantics fit the host).
  public var failureCount: Int {
    outcomes.reduce(into: 0) { count, outcome in
      if outcome.result != nil { count += 1 }
    }
  }
}
