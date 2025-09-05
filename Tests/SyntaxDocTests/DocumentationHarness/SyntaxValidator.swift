//
//  SyntaxValidator.swift
//  SyntaxKit
//
//  Created by Leo Dion on 9/5/25.
//

internal protocol SyntaxValidator {
  func validateCode(_ code: String) throws(ValidationError)
}
extension SyntaxValidator {
  internal func validateSyntax(from parameters: any ValidationParameters) -> ValidationResult {
    do {
      // Validate the syntax directly from the code string
      try self.validateCode(parameters.code)

      // If syntax validation succeeded, return success
      // Note: This only validates syntax, not full compilation or execution
      return ValidationResult(
        parameters: parameters,
        testType: .parsing,
        error: nil
      )
    } catch {
      return ValidationResult(
        parameters: parameters,
        testType: .parsing,
        error: error
      )
    }
  }
}
