//
//  RunnerSetupError.swift
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

/// Why a render session couldn't be brought up. Decoupled from any caller:
/// the `Runner` session initializer reports *what* failed; the caller (CLI,
/// build plugin, in-process driver) decides how to present it and which exit
/// code to use.
public enum RunnerSetupError: Error {
  /// The libSyntaxKit directory couldn't be resolved from the supplied
  /// candidates or the bundle-relative fallbacks. Carries the underlying
  /// `CLIError` describing the lookup.
  case libResolutionFailed(any Error)
  /// The bundle's recorded `swift --version` differs from the local one,
  /// so spawning `swift` would hit a swiftmodule-version mismatch.
  case toolchainMismatch(bundle: String, local: String)
}
