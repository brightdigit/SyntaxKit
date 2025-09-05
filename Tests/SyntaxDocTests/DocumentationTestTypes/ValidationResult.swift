import Foundation

internal struct ValidationResult {
  internal let parameters: any ValidationParameters
  internal let testType: TestType
  internal let error: ValidationError?

  /// Returns true if validation was successful (no error)
  internal var isSuccess: Bool {
    error == nil
  }

  internal var isSkipped: Bool {
    error?.isSkipped ?? false
  }

  // MARK: - Convenience Properties
  internal var fileURL: URL {
    parameters.fileURL
  }

  internal var lineNumber: Int {
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
