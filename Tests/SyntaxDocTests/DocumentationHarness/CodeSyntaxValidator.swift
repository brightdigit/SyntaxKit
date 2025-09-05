import Foundation
import SwiftParser
import SwiftSyntax









/// Validates Swift code examples for syntax correctness
internal struct CodeSyntaxValidator : SyntaxValidator, Sendable{

  /// Validates Swift syntax by parsing the code content
  /// - Parameter code: The Swift code to validate
  /// - Throws: SwiftSyntaxValidationError if validation failed
  internal func validateCode(_ code: String) throws(ValidationError) {
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
