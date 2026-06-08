//
//  RunError.swift
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

#if canImport(Subprocess)

  /// Typed error surfaced by `Runner`. It decouples the renderer from the CLI:
  /// `Runner` reports *what* went wrong, and `Skit.Run.run` decides the process
  /// exit code (so the engine can also be driven in-process from a library).
package enum RunError: Error {
    /// The input path was invalid — missing, or a directory given without `-o`.
    case invalidInput(String)
    /// Single-file mode: the spawned `swift` exited non-zero. Carries that code
    /// (e.g. a compile failure, `124` on timeout, `128 + signal`).
    case renderFailed(exitCode: Int32)
    /// Directory mode: at least one input failed; the batch exit code is `1`.
    case batchFailed
    /// A wrapped Foundation/Subprocess failure (file read/write, spawn error)
    /// that has no dedicated exit-code mapping.
    case unexpected(any Error)
  }

#endif
