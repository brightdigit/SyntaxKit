//
//  SingleFileRender.swift
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

/// Result of `Runner.renderFile`. Both fields may be populated on success —
/// the spawned `swift` can emit warnings to `stderr` alongside a valid
/// `stdout`. The caller decides where the bytes go (file, stdout, in-memory).
public struct SingleFileRender: Sendable {
  /// Rendered Swift source produced by the wrapped program.
  public let stdout: Data
  /// Compiler diagnostics from the spawned `swift`, with the wrapper path
  /// rewritten back to the original input. Empty when the toolchain was silent.
  public let stderr: String

  /// Creates a single-file render result from the rendered `stdout` bytes and
  /// any `stderr` diagnostics.
  public init(stdout: Data, stderr: String) {
    self.stdout = stdout
    self.stderr = stderr
  }
}
