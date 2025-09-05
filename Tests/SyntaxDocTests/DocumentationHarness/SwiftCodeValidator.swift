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
  
  internal init(
    code: String,
    fileURL: URL,
    lineNumber: Int,
    blockIndex: Int,
    blockType: CodeBlockType
  ) {
    self.code = code
    self.fileURL = fileURL
    self.lineNumber = lineNumber
    self.blockIndex = blockIndex
    self.blockType = blockType
  }
}

/// Result of Swift code validation
internal struct SyntaxValidationResult {
  internal let success: Bool
  internal let error: String?
}

/// Validates Swift code examples for syntax correctness
internal class SwiftCodeValidator {
  
  // MARK: - Public Methods
  
  /// Validates a Swift code example
  /// - Parameter parameters: The validation parameters containing code, file URL, and line number
  /// - Returns: A ValidationResult indicating success or failure
  internal func validateSwiftExample(
    _ parameters: any SwiftValidationParameters
  )  -> ValidationResult {
    let code = parameters.code
    let fileURL = parameters.fileURL
    let lineNumber = parameters.lineNumber
    do {
      // Create a temporary Swift file for testing
      let tempFile = try createTemporarySwiftFile(with: code)
      defer { try? FileManager.default.removeItem(at: tempFile) }

      // First, try to validate the syntax
      let validationResult = try  validateSwiftSyntax(tempFile)

      if !validationResult.success {
        return ValidationResult(
          success: false,
          fileURL: fileURL,
          lineNumber: lineNumber,
          testType: .parsing,
          error: "Syntax validation failed: \(validationResult.error ?? "Unknown error")"
        )
      }

      // If syntax validation succeeded, return success
      // Note: This only validates syntax, not full compilation or execution
      return ValidationResult(
        success: true,
        fileURL: fileURL,
        lineNumber: lineNumber,
        testType: .parsing,
        error: nil
      )
    } catch {
      return ValidationResult(
        success: false,
        fileURL: fileURL,
        lineNumber: lineNumber,
        testType: .parsing,
        error: "Syntax validation setup failed: \(error.localizedDescription)"
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
  
  /// Creates a temporary Swift file with proper imports and structure
  private func createTemporarySwiftFile(with code: String) throws -> URL {
    let tempDir = FileManager.default.temporaryDirectory
    let tempFile = tempDir.appendingPathComponent("DocTest-\(UUID()).swift")

    // Wrap the code with necessary imports and structure
    let wrappedCode = """
      import Foundation
      import SyntaxKit

      // Documentation example code:
      \(code)
      """

    try wrappedCode.write(to: tempFile, atomically: true, encoding: .utf8)
    return tempFile
  }

  /// Validates Swift syntax by parsing the file content
  private func validateSwiftSyntax(_ fileURL: URL)  throws -> SyntaxValidationResult {
    // For documentation tests, we validate Swift syntax using the Swift parser
    // This only checks for syntax errors, not full compilation or type checking

    let code = try String(contentsOf: fileURL)

    // Skip Package.swift examples and incomplete snippets
    if code.contains("Package(") || code.contains("dependencies:") || code.contains(".package(") {
      return SyntaxValidationResult(success: true, error: nil)
    }

    // Skip examples that obviously require runtime execution or have other imports
    if code.contains("@main") || (code.contains("import") && !code.contains("import SyntaxKit")) {
      return SyntaxValidationResult(success: true, error: nil)
    }

    // Skip shell commands or configuration examples
    if code.contains("swift build") || code.contains("swift test") || code.contains("swift package")
    {
      return SyntaxValidationResult(success: true, error: nil)
    }

    // For SyntaxKit examples, create a complete, parseable Swift source
    let cleanSource =
      code
      .replacingOccurrences(of: "import SyntaxKit", with: "")
      .replacingOccurrences(of: "import Foundation", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    // Skip if the remaining code is too fragmentary to parse
    if cleanSource.isEmpty || cleanSource.count < 10
      || (!cleanSource.contains("{") && !cleanSource.contains("let")
        && !cleanSource.contains("var"))
    {
      return SyntaxValidationResult(success: true, error: nil)
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
      return SyntaxValidationResult(
        success: false,
        error: "Syntax parsing detected errors in the code"
      )
    }

    return SyntaxValidationResult(success: true, error: nil)
  }
}
