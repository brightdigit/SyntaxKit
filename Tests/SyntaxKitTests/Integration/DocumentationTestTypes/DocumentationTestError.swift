import Foundation

internal enum DocumentationTestError: Error, CustomStringConvertible {
  case exampleValidationFailed(String)
  case sdkPathNotFound
  case fileNotFound(String)

  internal var description: String {
    switch self {
    case .exampleValidationFailed(let details):
      return "Documentation example validation failed: \(details)"
    case .sdkPathNotFound:
      return "Could not determine SDK path for compilation"
    case .fileNotFound(let path):
      return "Documentation file not found: \(path)"
    }
  }
}
