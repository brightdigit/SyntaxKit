//
//  Settings.swift
//  SyntaxKit
//
//  Created by Leo Dion on 9/5/25.
//

import Foundation

internal enum Settings {
  
  /// Default file extensions for documentation files
  internal static let defaultPathExtensions = ["md"]
  
  /// Project root directory calculated from the current file location
  internal static let projectRoot: URL = {
    let currentFileURL = URL(fileURLWithPath: #filePath)
    return
      currentFileURL
      .deletingLastPathComponent()  // Tests/SyntaxDocTests
      .deletingLastPathComponent()  // Tests
      .deletingLastPathComponent()  // Project root
  }()

  /// Document paths to search for documentation files
  internal static let docPaths = [
    "Sources/SyntaxKit/Documentation.docc",
    "README.md",
    "Examples",
  ]

  /// Resolves a relative file path to absolute path (public for use by test methods)
  @available(*, deprecated, renamed: "resolveFilePath")
  internal static func resolveRelativePath(_ filePath: String) throws -> URL {
    try resolveFilePath(filePath)
  }

  /// Resolves a relative file path to absolute path
  internal static func resolveFilePath(_ filePath: String) throws -> URL {
    if filePath.hasPrefix("/") {
      return .init(filePath: filePath)
    } else {
      return Self.projectRoot.appendingPathComponent(filePath)
    }
  }
}
