//
//  ValidationError.swift
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

import Foundation

/// Process execution errors
package enum ProcessError: Error, Sendable {
  /// Package.swift validation failed
  case packageValidationFailed
  /// Package validation setup failed
  case setupError(any Error)
}

/// Error type for Swift syntax validation failures
package enum ValidationError: Error, Sendable {
  /// Syntax parsing detected errors in the code
  case syntaxError

  /// The code contains elements that should be skipped
  case skippedCode(SkipReason)

  /// Process execution error
  case processError(ProcessError)

  /// Unexpected error during validation
  case unexpectedError(any Error)

  /// Reasons why code should be skipped
  package enum SkipReason: Equatable, Sendable {
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
  package var localizedDescription: String {
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
