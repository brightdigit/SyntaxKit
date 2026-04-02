import Foundation
import Testing

@testable import SyntaxKit

internal struct InitializerTests {
  @Test internal func testEmptyInit() {
    let initDecl = Initializer {}

    let expected = """
      init() {
      }
      """

    let normalizedGenerated = initDecl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testPublicInit() {
    let initDecl = Initializer {}.access(.public)

    let expected = """
      public init() {
      }
      """

    let normalizedGenerated = initDecl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testThrowingInit() {
    let initDecl = Initializer {}.throwing()

    let expected = """
      init() throws {
      }
      """

    let normalizedGenerated = initDecl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testAsyncInit() {
    let initDecl = Initializer {}.async()

    let expected = """
      init() async {
      }
      """

    let normalizedGenerated = initDecl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testPublicInitWithBody() {
    let initDecl = Initializer {
      Call("setup")
    }.access(.internal)

    let expected = """
      internal init() {
        setup()
      }
      """

    let normalizedGenerated = initDecl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }
}
