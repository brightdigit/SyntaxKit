import Foundation
import Testing

@testable import SyntaxKit

internal struct LiteralTests {
  @Test internal func testGroupWithLiterals() {
    let group = Group {
      Return {
        Literal.integer(1)
      }
    }
    let generated = group.generateCode()
    #expect(generated.trimmingCharacters(in: .whitespacesAndNewlines) == "return 1")
  }
}
