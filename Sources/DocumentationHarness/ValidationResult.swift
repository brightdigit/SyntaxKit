//
//  ValidationResult.swift
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

package struct ValidationResult {
  internal let parameters: any ValidationParameters
  package let testType: TestType
  package let error: ValidationError?

  /// Returns true if validation was successful (no error)
  package var isSuccess: Bool {
    error == nil
  }

  package var isSkipped: Bool {
    error?.isSkipped ?? false
  }

  // MARK: - Convenience Properties
  package var fileURL: URL {
    parameters.fileURL
  }

  package var lineNumber: Int {
    parameters.lineNumber
  }

  internal init(
    parameters: any ValidationParameters, testType: TestType, error: ValidationError? = nil
  ) {
    self.parameters = parameters
    self.testType = testType
    self.error = error
  }
}
