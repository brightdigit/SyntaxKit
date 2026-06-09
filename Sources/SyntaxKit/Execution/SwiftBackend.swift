//
//  SwiftBackend.swift
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

/// The two `swift`-toolchain operations a render session needs from a spawn
/// backend: capture the local toolchain version (feeds the toolchain check and
/// the cache key), and run `swift` for one `SwiftInvocation`.
///
/// SyntaxKit defines the contract; a Subprocess-based conformance lives in the
/// `skit` CLI. `Sendable` so the spawn method can be captured in `Runner`'s
/// `@Sendable` run closure.
package protocol SwiftBackend: Sendable {
  /// Verbatim `swift --version` output, or nil if the toolchain couldn't be
  /// queried.
  func captureSwiftVersion() async -> String?

  /// Spawns `swift` for `invocation` and normalizes the result into a
  /// `SwiftRunOutcome`.
  func runSwift(for invocation: SwiftInvocation) async throws -> SwiftRunOutcome
}
