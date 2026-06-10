//
//  RunnerBatchRenderTests.swift
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

/// Exercises the filesystem-free batch entry point `Runner.render(sources:)`:
/// it reads nothing and writes nothing, returning a `FileOutcome` per input
/// carrying the rendered `stdout` (or a `RunError`). Disabled on WASI because
/// the internal temp-wrapper write the render still performs is unreliable
/// there (see `RunnerRenderFailureTests`).
@Suite internal struct RunnerBatchRenderTests {
  /// Marker a source carries to make the stub backend fail that input.
  private static let failMarker = "// FAIL"

  /// A runner whose stub backend reads the wrapped program and reports a
  /// non-zero exit for any input whose source contains `failMarker`, and exit 0
  /// (with a fixed rendered payload) otherwise — so a single call can mix
  /// successes and failures without spawning `swift`.
  private func runner(toolchain: ToolchainVerification = .verified) -> Runner {
    Runner(
      libPath: "/does/not/matter",
      cache: nil,
      timeoutSeconds: 0,
      toolchainVerification: toolchain
    ) { invocation in
      let wrapped = (try? String(contentsOfFile: invocation.wrappedPath, encoding: .utf8)) ?? ""
      if wrapped.contains(Self.failMarker) {
        return .completed(ProcessResult(exitCode: 1, stdout: Data(), stderr: "boom\n"))
      }
      return .completed(ProcessResult(exitCode: 0, stdout: Data("RENDERED".utf8), stderr: ""))
    }
  }

  private func input(_ name: String, _ source: String) -> RenderInput {
    RenderInput(url: URL(fileURLWithPath: "/in/\(name)"), source: source)
  }

  @Test("An empty input set yields no outcomes without touching the backend")
  internal func emptyYieldsEmpty() async {
    let outcomes = await runner().render(sources: [])
    #expect(outcomes.isEmpty)
  }

  @Test(
    "Every successful input returns its rendered stdout with a nil result",
    .disabled(if: Platform.isWASI, "Render needs host filesystem/subprocess; not on WASI")
  )
  internal func successesCarryStdout() async {
    let outcomes = await runner().render(sources: [
      input("a.swift", "let a = 1\n"),
      input("b.swift", "let b = 2\n"),
    ])

    #expect(outcomes.count == 2)
    #expect(outcomes.failureCount == 0)
    for outcome in outcomes {
      #expect(outcome.result == nil)
      #expect(outcome.stdout == Data("RENDERED".utf8))
    }
    // The input URLs are preserved so the caller can reroot each output.
    #expect(Set(outcomes.map(\.input.lastPathComponent)) == ["a.swift", "b.swift"])
  }

  @Test(
    "A failing input is isolated: peers still render, failureCount reflects it",
    .disabled(if: Platform.isWASI, "Render needs host filesystem/subprocess; not on WASI")
  )
  internal func failureIsIsolated() async {
    let outcomes = await runner().render(sources: [
      input("ok.swift", "let ok = 1\n"),
      input("bad.swift", "\(Self.failMarker)\nlet bad = 2\n"),
    ])

    let byName = Dictionary(
      uniqueKeysWithValues: outcomes.map { ($0.input.lastPathComponent, $0) }
    )

    #expect(outcomes.count == 2)
    #expect(outcomes.failureCount == 1)

    let okOutcome = try? #require(byName["ok.swift"])
    #expect(okOutcome?.result == nil)
    #expect(okOutcome?.stdout == Data("RENDERED".utf8))

    let badOutcome = try? #require(byName["bad.swift"])
    #expect(badOutcome?.stdout.isEmpty == true)
    guard case .renderFailed(let exitCode, let stderr, let toolchain)? = badOutcome?.result else {
      Issue.record("expected .renderFailed for the marked input")
      return
    }
    #expect(exitCode == 1)
    #expect(stderr == "boom\n")
    #expect(toolchain == .verified)
  }
}
