//
//  TaskTimeoutTests.swift
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

/// Direct coverage for `Task.timeout(seconds:operation:)`: the operation-wins,
/// operation-throws, and watchdog-wins races.
@Suite internal struct TaskTimeoutTests {
  /// An error the operation throws to prove errors propagate out of the race.
  private struct OperationBoom: Error {}

  @Test("An operation that finishes before the deadline returns its value")
  internal func operationWinsReturnsValue() async throws {
    let value = try await Task.timeout(seconds: 60) { 42 }
    #expect(value == 42)
  }

  @Test("An operation that throws propagates the error out of the race")
  internal func operationThrowsPropagates() async {
    await #expect(throws: OperationBoom.self) {
      _ = try await Task.timeout(seconds: 60) {
        throw OperationBoom()
      }
    }
  }

  @Test(
    "When the watchdog wins, timeout returns nil",
    .disabled(if: Platform.isWASI, "No concurrency runtime / Task.sleep on WASI")
  )
  internal func watchdogWinsReturnsNil() async throws {
    // Operation sleeps well past the 1s deadline, so the watchdog fires first.
    let value = try await Task.timeout(seconds: 1) { () -> Int in
      try await Task<Never, Never>.sleep(nanoseconds: 30 * 1_000_000_000)
      return 42
    }
    #expect(value == nil)
  }
}
