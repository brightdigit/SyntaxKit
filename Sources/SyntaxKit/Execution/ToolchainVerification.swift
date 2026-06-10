//
//  ToolchainVerification.swift
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

/// Outcome of the bundle/local Swift-toolchain compatibility check performed
/// when a render session was created. Stored on the `Runner` and carried on
/// `RunError.renderFailed` so a caller can hint that an *unverified* toolchain
/// may be the real cause of a build error — swiftmodules aren't reliably
/// compatible across compiler versions. A confirmed *mismatch* never reaches
/// here; it fails session setup via `RunnerSetupError.toolchainMismatch`.
public enum ToolchainVerification: Sendable, Equatable {
  /// The bundle's recorded `swift --version` matched the local one.
  case verified
  /// The caller opted out of the check (`enforceToolchainCheck == false`).
  case notChecked
  /// The check ran but couldn't compare versions — the bundle had no
  /// toolchain stamp, or the local `swift --version` couldn't be captured —
  /// so compatibility is unknown.
  case unverified
}
