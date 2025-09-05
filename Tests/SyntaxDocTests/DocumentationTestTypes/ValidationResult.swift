import Foundation

internal struct ValidationResult {
  internal init(fileURL: URL, lineNumber: Int, testType: TestType, error: ValidationError? = nil) {
    self.fileURL = fileURL
    self.lineNumber = lineNumber
    self.testType = testType
    self.error = error
  }

  internal init(
    parameters: CodeBlockValidationParameters, testType: TestType, error: ValidationError? = nil
  ) {
    self.init(
      fileURL: parameters.fileURL, lineNumber: parameters.lineNumber, testType: testType,
      error: error)
  }

  internal let fileURL: URL
  internal let lineNumber: Int
  internal let testType: TestType
  internal let error: ValidationError?

  /// Returns true if validation was successful (no error)
  internal var isSuccess: Bool {
    error == nil
  }

  internal var isSkipped: Bool {
    error?.isSkipped ?? false
  }
}
