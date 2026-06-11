//
//  Settings.swift
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

internal enum Settings {
  /// Project root directory calculated with a 3-strategy fallback for cross-platform support
  internal static let projectRoot: URL = {
    let workingDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    // Strategy 1a: Sources/ in working directory (SPM/WASM/Linux)
    if FileManager.default.fileExists(atPath: workingDir.appendingPathComponent("Sources").path) {
      return workingDir
    }

    // Strategy 1b: Documentation.docc present in working directory.
    // The swift-build action's android-copy-files parameter copies Documentation.docc/ as
    // a flat sibling of the test binary. Strategy 1a always runs first, so a macOS project
    // root containing Sources/ will never reach this check.
    if FileManager.default.fileExists(
      atPath: workingDir.appendingPathComponent("Documentation.docc").path
    ) {
      return workingDir
    }

    // Strategy 2: Source-relative via #filePath (macOS/Linux CI)
    let sourceRelative = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()  // Tests/SyntaxDocTests
      .deletingLastPathComponent()  // Tests
      .deletingLastPathComponent()  // Project root
    if FileManager.default.fileExists(
      atPath: sourceRelative.appendingPathComponent("Sources").path
    ) {
      return sourceRelative
    }

    // Strategy 3: Walk up from working directory (nested execution contexts)
    var search = workingDir
    for _ in 0..<4 {
      if FileManager.default.fileExists(atPath: search.appendingPathComponent("Sources").path) {
        return search
      }
      search = search.deletingLastPathComponent()
    }

    // Fallback — will produce a clear error if Sources/ is still not found
    return sourceRelative
  }()

  /// Document paths to search for documentation files
  /// On WASM, limited to lightweight tutorial files only (no images, no Examples)
  /// due to WASM memory constraints (~144KB practical limit)
  internal static let docPaths: [String] = {
    #if os(Android)
      // android-copy-files copies Documentation.docc/ as last component to working dir
      return [
        "Documentation.docc/Tutorials/Quick-Start-Guide.md",
        "Documentation.docc/Tutorials/Creating-Macros-with-SyntaxKit.md",
      ]
    #elseif os(WASI)
      return [
        "Sources/SyntaxKit/Documentation.docc/Tutorials/Quick-Start-Guide.md",
        "Sources/SyntaxKit/Documentation.docc/Tutorials/Creating-Macros-with-SyntaxKit.md",
      ]
    #else
      return [
        "Sources/SyntaxKit/Documentation.docc",
        "README.md",
        "Examples",
      ]
    #endif
  }()

  /// Resolves a relative file path to absolute path
  internal static func resolveFilePath(_ filePath: String) throws -> URL {
    if filePath.hasPrefix("/") {
      if #available(iOS 16.0, watchOS 9.0, tvOS 16.0, macCatalyst 16.0, *) {
        return .init(filePath: filePath)
      } else {
        return .init(fileURLWithPath: filePath)
      }
    } else {
      #if os(Android)  // os(Android) is a valid Swift platform condition since Swift 5.9
        let resolvedPath = filePath
      #else
        let resolvedPath = "Sources/SyntaxKit/" + filePath
      #endif
      return Self.projectRoot.appendingPathComponent(resolvedPath)
    }
  }
}
