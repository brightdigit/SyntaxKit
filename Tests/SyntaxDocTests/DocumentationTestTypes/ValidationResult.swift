import Foundation

internal struct ValidationResult {
  internal init(success: Bool, fileURL: URL, lineNumber: Int, testType: TestType, error: String? = nil) {
    self.success = success
    self.fileURL = fileURL
    self.lineNumber = lineNumber
    self.testType = testType
    self.error = error
  }
  
  internal init(parameters: CodeBlockValidationParameters, testType: TestType, success: Bool, error: String? = nil) {
    self.init(success: success, fileURL: parameters.fileURL, lineNumber: parameters.lineNumber, testType: testType, error: error)
  }
  
  internal let success: Bool
  internal let fileURL: URL
  internal let lineNumber: Int
  internal let testType: TestType
  internal let error: String?
}
