//
//  RunnerRenderTests.swift
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

/// Single-file `render(source:originalPath:)` behaviour beyond the
/// `.renderFailed` path (covered by `RunnerRenderFailureTests`): the success
/// branch, the `.unexpected` wrapper, and the stderr path rewrite.
@Suite internal struct RunnerRenderTests {
  /// An error the stub backend throws to exercise the `.unexpected` wrapper.
  private struct BackendBoom: Error {}

  @Test(
    "A zero-exit render returns the backend's stdout as the rendered bytes",
    .disabled(if: Platform.isWASI, "Render needs host filesystem/subprocess; not on WASI")
  )
  internal func successReturnsStdout() async throws {
    let runner = Runner(libPath: "/x", cache: nil, timeoutSeconds: 0) { _ in
      .completed(ProcessResult(exitCode: 0, stdout: Data("rendered".utf8), stderr: ""))
    }
    let result = try await runner.render(source: "let x = 1\n")
    #expect(result.stdout == Data("rendered".utf8))
    #expect(result.stderr.isEmpty)
  }

  @Test(
    "A non-RunError thrown by the backend is wrapped as RunError.unexpected",
    .disabled(if: Platform.isWASI, "Render needs host filesystem/subprocess; not on WASI")
  )
  internal func backendErrorBecomesUnexpected() async {
    let runner = Runner(libPath: "/x", cache: nil, timeoutSeconds: 0) { _ in
      throw BackendBoom()
    }
    do {
      _ = try await runner.render(source: "let x = 1\n")
      Issue.record("expected render to throw")
    } catch let error as RunError {
      guard case .unexpected(let underlying) = error else {
        Issue.record("expected .unexpected, got \(error)")
        return
      }
      #expect(underlying is BackendBoom)
    } catch {
      Issue.record("expected RunError, got \(error)")
    }
  }

  @Test(
    "The wrapper temp path in stderr is rewritten back to the original input path",
    .disabled(if: Platform.isWASI, "Render needs host filesystem/subprocess; not on WASI")
  )
  internal func rewritesWrapperPathInStderr() async {
    // The stub echoes the invocation's wrapped-file path in stderr; the runner
    // must rewrite it back to the caller's originalPath before surfacing it.
    let runner = Runner(libPath: "/x", cache: nil, timeoutSeconds: 0) { invocation in
      .completed(
        ProcessResult(
          exitCode: 1,
          stdout: Data(),
          stderr: "\(invocation.wrappedPath):3:1: error: bad\n"
        )
      )
    }
    do {
      _ = try await runner.render(source: "let x = 1\n", originalPath: "/work/in.swift")
      Issue.record("expected render to throw")
    } catch let error as RunError {
      guard case .renderFailed(_, let stderr, _) = error else {
        Issue.record("expected .renderFailed, got \(error)")
        return
      }
      #expect(stderr.contains("/work/in.swift"))
      // The wrapper filename must be gone — proof the rewrite replaced the path.
      #expect(!stderr.contains("Input.wrapped.swift"))
    } catch {
      Issue.record("expected RunError, got \(error)")
    }
  }
}
