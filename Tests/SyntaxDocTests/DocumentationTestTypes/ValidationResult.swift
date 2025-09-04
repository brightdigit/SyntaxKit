import Foundation

internal struct ValidationResult {
  internal let success: Bool
  internal let fileURL: URL
  internal let lineNumber: Int
  internal let testType: TestType
  internal let error: String?
}
