//
//  SubprocessBackend.swift
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

import SyntaxKit

#if canImport(Subprocess)

  import Subprocess

  /// Subprocess-backed `SwiftBackend`: the real `swift`-spawning implementation
  /// skit hands to the render session. The one seam between the platform-
  /// agnostic engine in SyntaxKit and the Subprocess implementation.
  internal struct SubprocessBackend: SwiftBackend {
    /// Verbatim `swift --version` output, or nil on spawn failure. Capped at 4 KiB.
    internal func captureSwiftVersion() async -> String? {
      let result = try? await Subprocess.run(
        .name(Skit.swiftExecutableName),
        arguments: [Skit.Run.versionFlag],
        output: .string(limit: 4_096),
        error: .discarded
      )
      return result?.standardOutput
    }

    internal func runSwift(
      for invocation: SwiftInvocation
    ) async throws -> SwiftRunOutcome {
      try await Subprocess.Configuration.runSwift(for: invocation)
    }
  }

  extension Skit.Run {
    /// The active spawn backend, or nil when this platform has no Subprocess
    /// backend (Windows, embedded) and `run` therefore can't spawn `swift`.
    internal static let swiftBackend: (any SwiftBackend)? = SubprocessBackend()
  }

#else

  extension Skit.Run {
    /// No Subprocess backend on this platform — `run` reports `unsupportedPlatform`.
    internal static let swiftBackend: (any SwiftBackend)? = nil
  }

#endif
