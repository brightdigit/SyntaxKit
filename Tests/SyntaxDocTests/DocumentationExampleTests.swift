//
//  DocumentationExampleTests.swift
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

import DocumentationHarness
import Foundation
import Testing

/// Integration tests that validate all code examples in DocC documentation
@Suite("Documentation Code Examples")
internal struct DocumentationExampleTests {
  private let testHarness = DocumentationValidator()

  /// Test harness that extracts and validates Swift code examples from documentation
  @Test("All documentation code examples compile and execute correctly")
  internal func validateAllDocumentationExamples() throws {
    let results = try testHarness.validate(
      relativePaths: Settings.docPaths,
      atProjectRoot: Settings.projectRoot
    )

    // Report any failures
    let failures = results.filter { !$0.isSuccess && !$0.isSkipped }
    if !failures.isEmpty {
      let failureReport = failures.map { result in
        let path: String
        if #available(iOS 16.0, watchOS 9.0, tvOS 16.0, macCatalyst 16.0, *) {
          path = result.fileURL.path()
        } else {
          path = result.fileURL.path
        }
        return
          "\(path):\(result.lineNumber) - \(result.error?.localizedDescription ?? "Unknown error")"
      }
      .joined(separator: "\n")

      throw DocumentationTestError.exampleValidationFailed(
        "Code examples failed validation:\n\(failureReport)"
      )
    }

    // Log success summary
    print("✅ Validated \(results.count) code examples from documentation")
  }

  @Test("Quick Start Guide examples work correctly")
  internal func validateQuickStartGuideExamples() throws {
    let quickStartFile = try Settings.resolveFilePath(
      "Documentation.docc/Tutorials/Quick-Start-Guide.md"
    )
    let results = try testHarness.validateFile(at: quickStartFile)

    // Specific validation for Quick Start examples
    #expect(!results.isEmpty, "Quick Start Guide should contain code examples")
    #expect(
      results.allSatisfy { $0.isSuccess || $0.isSkipped },
      "All Quick Start examples should compile successfully"
    )
  }

  @Test("Creating Macros tutorial examples work correctly")
  internal func validateMacroTutorialExamples() throws {
    let macroTutorialFile = try Settings.resolveFilePath(
      "Documentation.docc/Tutorials/Creating-Macros-with-SyntaxKit.md"
    )
    let results = try testHarness.validateFile(at: macroTutorialFile)

    // Macro examples should compile (though they may not execute without full macro setup)
    let compileResults = results.filter { $0.testType == .parsing }
    #expect(
      compileResults.allSatisfy { $0.isSuccess || $0.isSkipped },
      "All macro examples should compile successfully")
  }
}
