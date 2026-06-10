//
//  FileManagerFileSystemTests.swift
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

@Suite internal struct FileManagerFileSystemTests {
  private let fileManager = FileManager.default

  /// Creates a fresh empty temp directory, runs `body` against it, and removes
  /// it afterward.
  private func withTempDir(_ body: (URL) throws -> Void) throws {
    let dir = fileManager.temporaryDirectory
      .appendingPathComponent("fs-\(UUID().uuidString)")
    try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: dir) }
    try body(dir)
  }

  // MARK: - pathKind

  @Test("pathKind classifies directory, file, and missing paths")
  internal func pathKindClassifies() throws {
    try withTempDir { dir in
      #expect(fileManager.pathKind(atPath: dir.path) == .directory)

      let file = dir.appendingPathComponent("a.txt")
      try Data("x".utf8).write(to: file)
      #expect(fileManager.pathKind(atPath: file.path) == .file)

      #expect(fileManager.pathKind(atPath: dir.appendingPathComponent("nope").path) == .missing)
    }
  }

  // MARK: - fingerprint

  @Test("fingerprint reports byte size for an existing file")
  internal func fingerprintReportsSize() throws {
    try withTempDir { dir in
      let file = dir.appendingPathComponent("a.bin")
      try Data("hello".utf8).write(to: file)

      let fingerprint = try #require(fileManager.fingerprint(atPath: file.path))
      #expect(fingerprint.size == 5)
    }
  }

  @Test("fingerprint is nil for a missing file")
  internal func fingerprintMissing() throws {
    try withTempDir { dir in
      #expect(fileManager.fingerprint(atPath: dir.appendingPathComponent("nope").path) == nil)
    }
  }

  // MARK: - regularFiles

  @Test("regularFiles walks recursively, skips hidden + directories, sorted by path")
  internal func regularFilesWalk() throws {
    try withTempDir { dir in
      let sub = dir.appendingPathComponent("sub")
      try fileManager.createDirectory(at: sub, withIntermediateDirectories: true)
      try Data("1".utf8).write(to: dir.appendingPathComponent("b.swift"))
      try Data("2".utf8).write(to: dir.appendingPathComponent("a.swift"))
      try Data("3".utf8).write(to: sub.appendingPathComponent("c.swift"))
      try Data("4".utf8).write(to: dir.appendingPathComponent(".hidden"))

      let files = try fileManager.regularFiles(under: dir)
      let names = files.map(\.lastPathComponent)

      // The hidden file and the `sub` directory itself are excluded; nested
      // files are included; the result is sorted by full path.
      #expect(names == ["a.swift", "b.swift", "c.swift"])
      #expect(files == files.sorted { $0.path < $1.path })
    }
  }

  @Test("regularFiles yields nothing for a missing directory")
  internal func regularFilesMissingDir() throws {
    try withTempDir { dir in
      // `enumerator(at:)` returns an empty (non-nil) enumerator for a missing
      // directory rather than nil, so the walk yields an empty list rather than
      // throwing — matching the directory-mode behavior of treating an empty
      // input set as a no-op.
      let missing = dir.appendingPathComponent("does-not-exist")
      let files = try fileManager.regularFiles(under: missing)
      #expect(files.isEmpty)
    }
  }

  // MARK: - writeData

  @Test("writeData creates intermediate directories")
  internal func writeDataCreatesIntermediates() throws {
    try withTempDir { dir in
      let destination = dir.appendingPathComponent("a/b/c/out.txt")
      try fileManager.writeData(Data("payload".utf8), to: destination)

      #expect(fileManager.pathKind(atPath: destination.path) == .file)
      #expect(try Data(contentsOf: destination) == Data("payload".utf8))
    }
  }

  // MARK: - URL.rerooted

  @Test("rerooted preserves the relative subpath under a new base")
  internal func rerootedPreservesSubpath() {
    let input = URL(fileURLWithPath: "/in/sub/a.swift")
    let rerooted = input.rerooted(
      from: URL(fileURLWithPath: "/in"),
      onto: URL(fileURLWithPath: "/out")
    )
    #expect(rerooted.path == "/out/sub/a.swift")
  }
}
