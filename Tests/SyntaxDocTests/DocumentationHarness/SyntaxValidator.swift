//
//  SyntaxValidator.swift
//  SyntaxKit
//
//  Created by Leo Dion on 9/5/25.
//


protocol SyntaxValidator {
  func validateCode(_ code: String) throws(ValidationError)
}
extension SyntaxValidator {
  func validateSyntax(from parameters: any ValidationParameters) -> ValidationResult {
    let code = parameters.code
    let fileURL = parameters.fileURL
    let lineNumber = parameters.lineNumber

    do {
      // Validate the syntax directly from the code string
      try self.validateCode(code)

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
}
