//
//  Task+Timeout.swift
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

extension Task where Failure == any Error, Success: Sendable {
  /// Runs `operation`, returning its value, or `nil` if `seconds` elapses
  /// first. The operation and a sleep watchdog race in a throwing task group;
  /// whichever finishes first wins and the loser is cancelled.
  ///
  /// Takes seconds rather than a `Duration` so the engine stays buildable on
  /// the package's minimum deployment targets — `Duration` requires iOS 16 /
  /// tvOS 16 / watchOS 9, whereas `Task.sleep(nanoseconds:)` back-deploys.
  public static func timeout(
    seconds: Int,
    operation: @escaping @Sendable () async throws -> Success
  ) async throws -> Success? {
    try await withThrowingTaskGroup(of: Success?.self) { group in
      group.addTask { try await operation() }
      group.addTask {
        // Bare `Task` here means `Task<Success, any Error>`, which has no
        // `sleep`; spell out the never-returning task to reach it.
        try await Task<Never, Never>.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
        return nil
      }
      let first = try await group.next()!
      group.cancelAll()
      return first
    }
  }
}
