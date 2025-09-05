import Foundation

/// Process execution errors
internal enum ProcessError: Error, Sendable {
  /// Package.swift validation failed
  case packageValidationFailed
  /// Package validation setup failed
  case setupError(any Error)
}

/// Error type for Swift syntax validation failures
internal enum ValidationError: Error, Sendable {
  /// Syntax parsing detected errors in the code
  case syntaxError

  /// The code contains elements that should be skipped
  case skippedCode(SkipReason)

  /// Process execution error
  case processError(ProcessError)

  /// Unexpected error during validation
  case unexpectedError(any Error)

  /// Reasons why code should be skipped
  internal enum SkipReason: Equatable, Sendable {
    /// Package.swift or dependency configuration
    case packageFile
    /// Contains @main or non-SyntaxKit imports
    case mainOrNonSyntaxKitImports
    /// Shell command or configuration example
    case shellCommand
    /// Code is too fragmentary to parse meaningfully
    case fragmentaryCode
    /// Code is empty or too short to validate
    case emptyOrTooShort
  }

  /// Returns a human-readable description of the error
  internal var localizedDescription: String {
    switch self {
    case .unexpectedError(let error):
      return "Unexpected error: \(error.localizedDescription)"
    case .syntaxError:
      return "Syntax parsing detected errors in the code"
    case .skippedCode(let reason):
      switch reason {
      case .packageFile:
        return "Code skipped: Package.swift or dependency configuration"
      case .mainOrNonSyntaxKitImports:
        return "Code skipped: Contains @main or non-SyntaxKit imports"
      case .shellCommand:
        return "Code skipped: Shell command or configuration example"
      case .fragmentaryCode:
        return "Code is too fragmentary to parse meaningfully"
      case .emptyOrTooShort:
        return "Code is empty or too short to validate"
      }
    case .processError(let processError):
      switch processError {
      case .packageValidationFailed:
        return "Package.swift validation failed"
      case .setupError(let error):
        return "Package validation setup failed: \(error.localizedDescription)"
      }
    }
  }

  internal var isSkipped: Bool {
    switch self {
    case .skippedCode: return true
    default: return false
    }
  }
}
