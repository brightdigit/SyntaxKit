//
//  DocumentationTestHarness.swift
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

/// Harness for extracting and testing documentation code examples
package struct DocumentationTestHarness {
  /// Default file extensions for documentation files
  internal static let defaultPathExtensions = ["md"]
  /// Swift code validator instance
  private let codeValidator: any SyntaxValidator
  private let fileSearcher: any FileSearcher
  private let codeBlocksFrom: CodeBlockExtractor

  package init(
    codeValidator: any SyntaxValidator = CodeSyntaxValidator(),
    fileSearcher: any FileSearcher = FileManager.default,
    codeBlocksFrom: @escaping CodeBlockExtractor = CodeBlockExtraction.callAsFunction(_:)
  ) {
    self.codeValidator = codeValidator
    self.fileSearcher = fileSearcher
    self.codeBlocksFrom = codeBlocksFrom
  }

  /// Validates all code examples in all documentation files
  package func validate(
    relativePaths: [String], atProjectRoot projectRoot: URL,
    withPathExtensions pathExtensions: [String] = Self.defaultPathExtensions
  ) throws -> [ValidationResult] {
    let documentationFiles = try relativePaths.flatMap { docPath in
      let absolutePath = projectRoot.appendingPathComponent(docPath)
      return try self.fileSearcher.findDocumentationFiles(
        in: absolutePath,
        pathExtensions: pathExtensions
      )
    }
    var allResults: [ValidationResult] = []

    for filePath in documentationFiles {
      let results = try validateExamplesInFile(filePath)
      allResults.append(contentsOf: results)
    }

    return allResults
  }

  /// Validates code examples in a specific file
  package func validateExamplesInFile(_ fileURL: URL) throws -> [ValidationResult] {
    // let fullPath = try resolveFilePath(filePath)
    let content = try String(contentsOf: fileURL)

    let codeBlocks = try codeBlocksFrom(content)
    var results: [ValidationResult] = []

    for (index, codeBlock) in codeBlocks.enumerated() {
      try results.append(
        #require(
          validateCodeBlock(fileURL.codeBlock(codeBlock, at: index))
        )
      )
    }

    return results
  }

  /// Validates a single code block
  private func validateCodeBlock(
    _ parameters: CodeBlockValidationParameters
  ) -> ValidationResult? {
    switch parameters.codeBlock.blockType {
    case .example:
      // Test compilation and basic execution
      return codeValidator.validateSyntax(from: parameters)

    case .packageManifest:
      #if canImport(Foundation) && (os(macOS) || os(Linux))
        // Package.swift files need special handling
        var processError: ProcessError?
        do {
          try validatePackageManifest(parameters.code)
          processError = nil
        } catch {
          processError = error
        }
        return ValidationResult(
          parameters: parameters,
          testType: .parsing,
          error: processError.map { ValidationError.processError($0) }
        )
      #else
        return ValidationResult(
          parameters: parameters,
          testType: .skipped,
          error: nil
        )
      #endif
    case .shellCommand:
      // Skip shell commands for now
      return ValidationResult(
        parameters: parameters,
        testType: .skipped,
        error: nil
      )
    }
  }

  #if canImport(Foundation) && (os(macOS) || os(Linux))
    /// Validates a Package.swift manifest
    private func validatePackageManifest(
      _ code: String
    ) throws(ProcessError) {
      let process = Process()
      do {
        // Create temporary Package.swift and validate it parses
        let tempDir = FileManager.default.temporaryDirectory
          .appendingPathComponent("SyntaxKit-DocTest-\(UUID())")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let packageFile = tempDir.appendingPathComponent("Package.swift")
        try code.write(to: packageFile, atomically: true, encoding: .utf8)

        // Use swift package tools to validate
        process.currentDirectoryURL = tempDir
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["package", "describe", "--type", "json"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()
      } catch {
        throw .setupError(error)
      }

      guard process.terminationStatus == 0 else {
        return
      }

      throw .packageValidationFailed
    }
  #endif
}
