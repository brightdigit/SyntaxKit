import Foundation
import SwiftParser
import SwiftSyntax

/// Protocol defining the parameters required for Swift code validation
internal protocol SwiftValidationParameters {
  /// The Swift code to validate
  var code: String { get }

  /// The file URL where the code was found
  var fileURL: URL { get }

  /// The line number where the code was found
  var lineNumber: Int { get }
}

/// Parameters for validating code blocks with additional metadata
internal struct CodeBlockValidationParameters: SwiftValidationParameters, Sendable {
  internal let code: String
  internal let fileURL: URL
  internal let lineNumber: Int
  internal let blockIndex: Int
  internal let blockType: CodeBlockType
}

/// Validates Swift code examples for syntax correctness
internal class SwiftCodeValidator {
  // MARK: - Public Methods

  /// Validates a Swift code example
  /// - Parameter parameters: The validation parameters containing code, file URL, and line number
  /// - Returns: A ValidationResult indicating success or failure
  internal func validateSwiftExample(
    _ parameters: any SwiftValidationParameters
  ) -> ValidationResult {
    let code = parameters.code
    let fileURL = parameters.fileURL
    let lineNumber = parameters.lineNumber

    do {
      // Validate the syntax directly from the code string
      try validateSwiftSyntax(code)

      // If syntax validation succeeded, return success
      // Note: This only validates syntax, not full compilation or execution
      return ValidationResult(
        fileURL: fileURL,
        lineNumber: lineNumber,
        testType: .parsing,
        error: nil
      )
    } catch {
      return ValidationResult(
        fileURL: fileURL,
        lineNumber: lineNumber,
        testType: .parsing,
        error: error
      )
    }
  }

  /// Convenience method for backward compatibility
  /// - Parameters:
  ///   - code: The Swift code to validate
  ///   - fileURL: The file URL where the code was found
  ///   - lineNumber: The line number where the code was found
  /// - Returns: A ValidationResult indicating success or failure
  //  internal func validateSwiftExample(
  //    _ code: String,
  //    fileURL: URL,
  //    lineNumber: Int
  //  ) async -> ValidationResult {
  //    let parameters = SwiftValidationParametersImpl(
  //      code: code,
  //      fileURL: fileURL,
  //      lineNumber: lineNumber
  //    )
  //    return await validateSwiftExample(parameters)
  //  }

  // MARK: - Private Methods

  /// Validates Swift syntax by parsing the code content
  /// - Parameter code: The Swift code to validate
  /// - Throws: SwiftSyntaxValidationError if validation failed
  private func validateSwiftSyntax(_ code: String) throws(ValidationError) {
    // For documentation tests, we validate Swift syntax using the Swift parser
    // This only checks for syntax errors, not full compilation or type checking

    // Skip Package.swift examples and incomplete snippets
    if code.contains("Package(") || code.contains("dependencies:") || code.contains(".package(") {
      throw ValidationError.skippedCode(.packageFile)
    }

    // Skip examples that obviously require runtime execution or have other imports
    if code.contains("@main") || (code.contains("import") && !code.contains("import SyntaxKit")) {
      throw ValidationError.skippedCode(.mainOrNonSyntaxKitImports)
    }

    // Skip shell commands or configuration examples
    if code.contains("swift build") || code.contains("swift test") || code.contains("swift package")
    {
      throw ValidationError.skippedCode(.shellCommand)
    }

    // For SyntaxKit examples, create a complete, parseable Swift source
    let cleanSource =
      code
      .replacingOccurrences(of: "import SyntaxKit", with: "")
      .replacingOccurrences(of: "import Foundation", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    // Skip if the remaining code is too fragmentary to parse
    if cleanSource.isEmpty || cleanSource.count < 10 {
      throw ValidationError.skippedCode(.emptyOrTooShort)
    }

    if !cleanSource.contains("{") && !cleanSource.contains("let")
      && !cleanSource.contains("var")
    {
      throw ValidationError.skippedCode(.fragmentaryCode)
    }

    // Try to parse as complete Swift statements
    let wrappedSource = """
      func testExample() {
      \(cleanSource)
      }
      """

    let parsed = Parser.parse(source: wrappedSource)

    // Check for syntax errors in the parsed result
    if parsed.hasError {
      throw ValidationError.syntaxError
    }
  }
}
