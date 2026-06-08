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

  /// Typed error surfaced by `Runner`. It decouples the renderer from any
  /// particular caller: `Runner` reports *what* went wrong, and the caller
  /// (CLI, build plugin, in-process driver) decides how to present it.
package enum RunError: Error {
    /// The input path was invalid — missing, or a directory given without an
    /// output directory.
    case invalidInput(String)
    /// Single-file render: the spawned `swift` exited non-zero. Carries that
    /// code (e.g. a compile failure, `124` on timeout, `128 + signal`) and
    /// the (path-rewritten) stderr the toolchain emitted, so the caller can
    /// surface diagnostics without having to fish them out elsewhere.
    case renderFailed(exitCode: Int32, stderr: String)
    /// A wrapped Foundation/Subprocess failure (file read/write, spawn error)
    /// that has no dedicated mapping.
    case unexpected(any Error)
  }

#endif
