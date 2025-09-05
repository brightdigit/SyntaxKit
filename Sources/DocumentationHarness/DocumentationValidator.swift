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
import SwiftParser
import SwiftSyntax
import Testing

/// Test harness for extracting and validating Swift code examples from documentation
package struct DocumentationValidator: Validator {
  /// Swift code validator instance
  private let codeValidator: any SyntaxValidator
  private let codeBlocksFrom: CodeBlockExtractor

  /// Creates a new documentation test harness
  /// - Parameters:
  ///   - codeValidator: Validator for Swift code syntax (defaults to CodeSyntaxValidator)
  ///   - fileSearcher: File system searcher (defaults to FileManager.default)
  ///   - codeBlocksFrom: Function to extract code blocks from content
  package init(
    codeValidator: any SyntaxValidator = CodeSyntaxValidator(),
    codeBlocksFrom: @escaping CodeBlockExtractor = CodeBlockExtraction.callAsFunction(_:)
  ) {
    self.codeValidator = codeValidator
    self.codeBlocksFrom = codeBlocksFrom
  }

  /// Validates all Swift code examples in a specific documentation file
  /// - Parameter fileURL: URL of the file to validate
  /// - Returns: Array of validation results for code blocks in the file
  /// - Throws: Error if file cannot be read or parsed
  package func validateFile(at fileURL: URL) throws -> [ValidationResult] {
    // let fullPath = try resolveFilePath(filePath)
    let content = try String(contentsOf: fileURL)

    let codeBlocks = try codeBlocksFrom(content)
    var results: [ValidationResult] = []

    for (index, codeBlock) in codeBlocks.enumerated() {
      results.append(
        validateCodeBlock(fileURL.codeBlock(codeBlock, at: index))
      )
    }

    return results
  }

  /// Validates a single code block
  private func validateCodeBlock(
    _ parameters: CodeBlockValidationParameters
  ) -> ValidationResult {
    guard case .example = parameters.codeBlock.blockType else {
      return ValidationResult(
        parameters: parameters,
        testType: .skipped,
        error: nil
      )
    }
    // Test compilation and basic execution
    return codeValidator.validateSyntax(from: parameters)
  }
}
