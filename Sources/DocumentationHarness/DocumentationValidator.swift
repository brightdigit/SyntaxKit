//
//  DocumentationValidator.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

package import Foundation

package protocol DocumentationValidator {
  func validateFile(at fileURL: URL) throws -> [ValidationResult]
}

private let privateDefaultPathExtensions = ["md"]
extension DocumentationValidator {
  /// Default file extensions for documentation files
  package static var defaultPathExtensions: [String] {
    privateDefaultPathExtensions
  }

  /// Validates all Swift code examples found in documentation files
  /// - Parameters:
  ///   - relativePaths: Array of relative paths to search for documentation
  ///   - projectRoot: Root URL of the project
  ///   - pathExtensions: File extensions to search for (defaults to ["md"])
  /// - Returns: Array of validation results for all code blocks found
  /// - Throws: FileSearchError if file operations fail
  package func validate(
    relativePaths: [String],
    atProjectRoot projectRoot: URL,
    withPathExtensions pathExtensions: [String] = Self.defaultPathExtensions,
    using fileSearcher: any FileSearcher = FileManager.default
  ) throws -> [ValidationResult] {
    let documentationFiles = try relativePaths.flatMap { docPath in
      let absolutePath = projectRoot.appendingPathComponent(docPath)
      return try fileSearcher.findDocumentationFiles(
        in: absolutePath,
        pathExtensions: pathExtensions
      )
    }
    var allResults: [ValidationResult] = []

    for filePath in documentationFiles {
      let results = try validateFile(at: filePath)
      allResults.append(contentsOf: results)
    }

    return allResults
  }
}
