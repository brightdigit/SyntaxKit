//
//  RunnerRenderFailureTests.swift
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
import Testing

@testable import SyntaxKit

@Suite internal struct RunnerRenderFailureTests {
  /// Runs `render(source:originalPath:)` against in-memory source with a stub
  /// backend that always reports a non-zero exit, so the render fails
  /// deterministically without spawning `swift`. Returns the thrown `RunError`,
  /// or nil if the call unexpectedly succeeded.
  private func renderFailure(
    toolchain: ToolchainVerification
  ) async -> RunError? {
    let runner = Runner(
      libPath: "/does/not/matter",
      cache: nil,
      timeoutSeconds: 0,
      toolchainVerification: toolchain
    ) { _ in
      .completed(ProcessResult(exitCode: 1, stdout: Data(), stderr: "boom\n"))
    }

    do {
      // Omit `originalPath` — exercises the optional anonymous-snippet path.
      _ = try await runner.render(source: "let x = 1\n")
      return nil
    } catch {
      return error
    }
  }

  @Test(
    "renderFailed carries the session's toolchain verification and diagnostics",
    .disabled(if: Platform.isWASI, "Render needs host filesystem/subprocess; not on WASI")
  )
  internal func carriesUnverifiedToolchain() async {
    guard
      case .renderFailed(let exitCode, let stderr, let toolchain)? =
        await renderFailure(toolchain: .unverified)
    else {
      Issue.record("expected .renderFailed")
      return
    }
    #expect(exitCode == 1)
    #expect(stderr == "boom\n")
    #expect(toolchain == .unverified)
  }

  @Test(
    "renderFailed reflects a verified toolchain unchanged",
    .disabled(if: Platform.isWASI, "Render needs host filesystem/subprocess; not on WASI")
  )
  internal func reflectsVerifiedToolchain() async {
    guard
      case .renderFailed(_, _, let toolchain)? =
        await renderFailure(toolchain: .verified)
    else {
      Issue.record("expected .renderFailed")
      return
    }
    #expect(toolchain == .verified)
  }

  @Test("A directly-constructed Runner defaults to notChecked")
  internal func defaultsToNotChecked() {
    let runner = Runner(libPath: "/x", cache: nil, timeoutSeconds: 0) { _ in
      .completed(ProcessResult(exitCode: 0, stdout: Data(), stderr: ""))
    }
    #expect(runner.toolchainVerification == .notChecked)
  }
}
