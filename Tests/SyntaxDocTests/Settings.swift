//
//  Settings.swift
//  SyntaxKit
//
//  Created by Leo Dion on 9/5/25.
//

import Foundation

internal enum Settings {
  /// Project root directory calculated with a 3-strategy fallback for cross-platform support
  internal static let projectRoot: URL = {
    // Strategy 1: Working directory (most reliable for SPM/WASM/Android)
    let workingDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    if FileManager.default.fileExists(atPath: workingDir.appendingPathComponent("Sources").path) {
      return workingDir
    }

    // Strategy 2: Source-relative via #filePath (macOS/Linux CI)
    let sourceRelative = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()  // Tests/SyntaxDocTests
      .deletingLastPathComponent()  // Tests
      .deletingLastPathComponent()  // Project root
    if FileManager.default.fileExists(
      atPath: sourceRelative.appendingPathComponent("Sources").path)
    {
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
    #if os(WASI)
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
      return Self.projectRoot.appendingPathComponent(filePath)
    }
  }
}
