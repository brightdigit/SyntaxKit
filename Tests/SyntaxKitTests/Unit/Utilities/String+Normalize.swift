import Foundation

extension String {
  internal func normalize() -> String {
    self
      .replacingOccurrences(of: "\\s*:\\s*", with: ": ", options: .regularExpression)
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
