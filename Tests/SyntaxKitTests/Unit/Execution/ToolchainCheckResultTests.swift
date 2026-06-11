//
//  ToolchainCheckResultTests.swift
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

@Suite internal struct ToolchainCheckResultTests {
  private static let stampFilename = "swift-version.txt"

  /// Creates a fresh temp lib dir, optionally seeded with a `swift-version.txt`
  /// stamp, runs `body` against its path, and removes the dir afterward.
  private func withLibDir(
    stamp: String?,
    _ body: (String) throws -> Void
  ) throws {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("toolchain-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    if let stamp {
      try Data(stamp.utf8).write(to: dir.appendingPathComponent(Self.stampFilename))
    }
    try body(dir.path)
  }

  @Test("Identical bundle/local versions match")
  internal func match() throws {
    try withLibDir(stamp: "swift 6.1") { libPath in
      let result = ToolchainCheckResult(libPath: libPath, swiftVersion: "swift 6.1")
      guard case .match = result else {
        Issue.record("expected .match, got \(result)")
        return
      }
    }
  }

  @Test("Trailing whitespace and newlines are normalized before comparison")
  internal func normalizesWhitespace() throws {
    try withLibDir(stamp: "swift 6.1\n  ") { libPath in
      let result = ToolchainCheckResult(libPath: libPath, swiftVersion: "swift 6.1\n")
      guard case .match = result else {
        Issue.record("expected .match, got \(result)")
        return
      }
    }
  }

  @Test("Differing versions report a mismatch carrying both strings")
  internal func mismatch() throws {
    try withLibDir(stamp: "swift 6.1") { libPath in
      let result = ToolchainCheckResult(libPath: libPath, swiftVersion: "swift 6.2")
      guard case .mismatch(let bundle, let local) = result else {
        Issue.record("expected .mismatch, got \(result)")
        return
      }
      #expect(bundle == "swift 6.1")
      #expect(local == "swift 6.2")
    }
  }

  @Test("A missing stamp file yields stampMissing")
  internal func missingStamp() throws {
    try withLibDir(stamp: nil) { libPath in
      let result = ToolchainCheckResult(libPath: libPath, swiftVersion: "swift 6.1")
      guard case .stampMissing = result else {
        Issue.record("expected .stampMissing, got \(result)")
        return
      }
    }
  }

  @Test("A nil local version yields stampMissing")
  internal func nilLocalVersion() throws {
    try withLibDir(stamp: "swift 6.1") { libPath in
      let result = ToolchainCheckResult(libPath: libPath, swiftVersion: nil)
      guard case .stampMissing = result else {
        Issue.record("expected .stampMissing, got \(result)")
        return
      }
    }
  }
}
