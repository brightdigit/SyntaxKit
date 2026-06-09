//
//  SkitSubprocessTimeoutTests.swift
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

  import Foundation
  import Subprocess
  import Testing

  // Regression test for swift-subprocess #256:
  // <https://github.com/swiftlang/swift-subprocess/issues/256>
  //
  // The skit timeout watchdog (Sources/skit/Runner.swift) races a Subprocess
  // run() call against `Task.sleep(timeout)`. On timeout it calls
  // `group.cancelAll()`, which Subprocess turns into a teardown sequence on
  // the spawned `swift`. The reported bug: when the spawned child has a
  // grandchild that inherited the pipe FDs, the parent's stream read can hang
  // waiting for an EOF that won't arrive until the grandchild exits.
  //
  // skit's real-world trigger is `swift Input.swift`, which fork-exec's the
  // Swift frontend + linker as grandchildren. We approximate that here with a
  // shell pipeline that forks a background `sleep` holding stderr open.
  @Suite("Subprocess timeout-cancel")
  internal struct SkitSubprocessTimeoutTests {
    private enum Outcome: Equatable, Sendable {
      case completed(TerminationStatus)
      case timedOut
    }

    @Test(
      "cancel-on-timeout completes within a bounded wall-time when grandchildren hold pipe fds"
    )
    internal func cancelWithBackgroundedGrandchild() async throws {
      let start = ContinuousClock.now

      let outcome: Outcome = try await withThrowingTaskGroup(of: Outcome.self) { group in
        group.addTask {
          // Outer shell spawns a backgrounded grandchild that holds stderr
          // open for 30s, then itself sleeps 30s. Both must be forcibly
          // killed by the teardown to free our stream reads.
          let record = try await run(
            .name("sh"),
            arguments: ["-c", "(sleep 30 >/dev/null 2>&1 &) ; sleep 30"],
            output: .discarded,
            error: .discarded
          )
          return .completed(record.terminationStatus)
        }
        group.addTask {
          try await Task.sleep(for: .seconds(1))
          return .timedOut
        }
        let first = try await group.next()!
        group.cancelAll()
        return first
      }

      let elapsed = ContinuousClock.now - start

      #expect(
        outcome == .timedOut,
        "timeout task should win the race against a 30s sleep"
      )
      // Generous bound: cancellation + Subprocess teardown should complete
      // well under 15s. If swift-subprocess #256 triggers, this test fails
      // (the run task hangs ≥30s waiting for the grandchild to release the
      // stderr pipe).
      #expect(
        elapsed < .seconds(15),
        "timeout-cancel took \(elapsed); possible swift-subprocess #256 regression"
      )
    }
  }

#endif
