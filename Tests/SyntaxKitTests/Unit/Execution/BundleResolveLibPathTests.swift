//
//  BundleResolveLibPathTests.swift
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

/// `Bundle.resolveLibPath` candidate handling plus the two bundle-relative
/// fallbacks (`<exec-dir>/lib`, `<exec-dir>/../lib/skit`), driven through the
/// injectable `executableURL` seam against fixture trees.
@Suite internal struct BundleResolveLibPathTests {
  /// Creates a unique temp directory torn down by the returned cleanup closure.
  private func makeTempDir() throws -> (url: URL, cleanup: () -> Void) {
    let fileManager = FileManager.default
    let url = fileManager.temporaryDirectory
      .appendingPathComponent("resolvelib-\(UUID().uuidString)")
    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    return (url, { try? FileManager.default.removeItem(at: url) })
  }

  /// Materializes `dir` as a SyntaxKit lib dir by dropping in the marker dylib
  /// `isLibDir` looks for.
  private func makeLibDir(at dir: URL) throws {
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let marker = dir.appendingPathComponent("SyntaxKit".dylibFilename)
    try Data().write(to: marker)
  }

  @Test("A valid explicit candidate is returned verbatim")
  internal func explicitCandidateReturned() throws {
    let temp = try makeTempDir()
    defer { temp.cleanup() }
    let lib = temp.url.appendingPathComponent("lib")
    try makeLibDir(at: lib)

    let resolved = try Bundle.main.resolveLibPath(candidates: [lib.path])
    #expect(resolved == lib.path)
  }

  @Test("An explicit candidate that isn't a lib dir throws CLIError")
  internal func badCandidateThrows() throws {
    let temp = try makeTempDir()
    defer { temp.cleanup() }
    // Exists but has no marker dylib.
    #expect(throws: CLIError.self) {
      _ = try Bundle.main.resolveLibPath(candidates: [temp.url.path])
    }
  }

  @Test("The adjacent <exec-dir>/lib layout is found when no candidate matches")
  internal func adjacentFallback() throws {
    let temp = try makeTempDir()
    defer { temp.cleanup() }
    let binDir = temp.url.appendingPathComponent("bin")
    try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
    try makeLibDir(at: binDir.appendingPathComponent("lib"))

    let resolved = try Bundle.main.resolveLibPath(
      candidates: [nil],
      executableURL: binDir.appendingPathComponent("skit")
    )
    #expect(resolved.hasSuffix("/lib"))
    #expect(FileManager.default.isLibDir(resolved))
  }

  @Test("The Homebrew <exec-dir>/../lib/skit layout is found as a fallback")
  internal func homebrewFallback() throws {
    let temp = try makeTempDir()
    defer { temp.cleanup() }
    let binDir = temp.url.appendingPathComponent("bin")
    try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
    // Only the brew layout exists (no adjacent <exec-dir>/lib), so the brew
    // branch is what resolves.
    try makeLibDir(at: temp.url.appendingPathComponent("lib/skit"))

    let resolved = try Bundle.main.resolveLibPath(
      candidates: [nil],
      executableURL: binDir.appendingPathComponent("skit")
    )
    #expect(resolved.hasSuffix("/lib/skit"))
    #expect(FileManager.default.isLibDir(resolved))
  }

  @Test("With no candidate and no fallback layout, resolveLibPath throws CLIError")
  internal func nothingFoundThrows() throws {
    let temp = try makeTempDir()
    defer { temp.cleanup() }
    let binDir = temp.url.appendingPathComponent("bin")
    try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)

    #expect(throws: CLIError.self) {
      _ = try Bundle.main.resolveLibPath(
        candidates: [nil],
        executableURL: binDir.appendingPathComponent("skit")
      )
    }
  }
}
