//
//  RunInputTests.swift
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

/// `RunInput.resolve` is the sole producer of `RunError.invalidInput`: it stats
/// the path and enforces the per-mode output rules.
@Suite internal struct RunInputTests {
  @Test("A file path resolves to .singleFile, carrying the output through")
  internal func existingFileIsSingleFile() throws {
    let file = FileManager.default.temporaryDirectory
      .appendingPathComponent("runinput-\(UUID().uuidString).swift")
    try Data("let x = 1\n".utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }

    let resolved = try RunInput.resolve(input: file.path, output: "/out.swift")
    guard case .singleFile(let inputPath, let outputPath) = resolved else {
      Issue.record("expected .singleFile, got \(resolved)")
      return
    }
    #expect(inputPath == file.path)
    #expect(outputPath == "/out.swift")
  }

  @Test("A directory with an output resolves to .directory")
  internal func directoryWithOutput() throws {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("runinput-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let resolved = try RunInput.resolve(input: dir.path, output: "/out")
    guard case .directory(let inputDir, let outputDir) = resolved else {
      Issue.record("expected .directory, got \(resolved)")
      return
    }
    #expect(inputDir == dir.path)
    #expect(outputDir == "/out")
  }

  @Test("A non-existent path throws RunError.invalidInput")
  internal func missingPathIsInvalidInput() {
    let missing = "/no/such/path-\(UUID().uuidString).swift"
    do {
      _ = try RunInput.resolve(input: missing, output: nil)
      Issue.record("expected resolve to throw")
    } catch let error as RunError {
      guard case .invalidInput(let message) = error else {
        Issue.record("expected .invalidInput, got \(error)")
        return
      }
      #expect(message.contains("does not exist"))
    } catch {
      Issue.record("expected RunError, got \(error)")
    }
  }

  @Test("A directory input without an output throws RunError.invalidInput")
  internal func directoryWithoutOutputIsInvalidInput() throws {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("runinput-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    do {
      _ = try RunInput.resolve(input: dir.path, output: nil)
      Issue.record("expected resolve to throw")
    } catch let error as RunError {
      guard case .invalidInput(let message) = error else {
        Issue.record("expected .invalidInput, got \(error)")
        return
      }
      #expect(message.contains("-o"))
    } catch {
      Issue.record("expected RunError, got \(error)")
    }
  }
}
