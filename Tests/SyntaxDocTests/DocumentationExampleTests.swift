import DocumentationHarness
import Foundation
import Testing

/// Integration tests that validate all code examples in DocC documentation
@Suite("Documentation Code Examples")
internal struct DocumentationExampleTests {
  /// Test harness that extracts and validates Swift code examples from documentation
  @Test("All documentation code examples compile and execute correctly")
  internal func validateAllDocumentationExamples() throws {
    let testHarness = DocumentationTestHarness()
    let results = try testHarness.validate(
      relativePaths: Settings.docPaths, atProjectRoot: Settings.projectRoot)

    // Report any failures
    let failures = results.filter { !$0.isSuccess && !$0.isSkipped }
    if !failures.isEmpty {
      let failureReport = failures.map { result in
        // swiftlint:disable:next line_length
        "\(result.fileURL.path()):\(result.lineNumber) - \(result.error?.localizedDescription ?? "Unknown error")"
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
    let testHarness = DocumentationTestHarness()
    let quickStartFile = try Settings.resolveFilePath(
      "Sources/SyntaxKit/Documentation.docc/Tutorials/Quick-Start-Guide.md"
    )
    let results = try testHarness.validateExamplesInFile(quickStartFile)

    // Specific validation for Quick Start examples
    #expect(!results.isEmpty, "Quick Start Guide should contain code examples")
    #expect(
      results.allSatisfy { $0.isSuccess || $0.isSkipped },
      "All Quick Start examples should compile successfully"
    )
  }

  @Test("Creating Macros tutorial examples work correctly")
  internal func validateMacroTutorialExamples() throws {
    let testHarness = DocumentationTestHarness()
    let macroTutorialFile = try Settings.resolveFilePath(
      "Sources/SyntaxKit/Documentation.docc/Tutorials/Creating-Macros-with-SyntaxKit.md"
    )
    let results = try testHarness.validateExamplesInFile(macroTutorialFile)

    // Macro examples should compile (though they may not execute without full macro setup)
    let compileResults = results.filter { $0.testType == .parsing }
    #expect(
      compileResults.allSatisfy { $0.isSuccess || $0.isSkipped },
      "All macro examples should compile successfully")
  }

  @Test("Enum Generator examples work correctly")
  internal func validateEnumGeneratorExamples() throws {
    let testHarness = DocumentationTestHarness()
    let enumExampleFile = try Settings.resolveFilePath(
      "Sources/SyntaxKit/Documentation.docc/Examples/EnumGenerator.md"
    )
    let results = try testHarness.validateExamplesInFile(enumExampleFile)

    // Check that enum generation examples actually work
    let executionResults = results.filter { $0.testType == .execution }
    #expect(
      executionResults.allSatisfy { $0.isSuccess || $0.isSkipped },
      "Enum generation examples should execute correctly")
  }
}
