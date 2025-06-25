import SyntaxKit
import Testing

@Suite
internal struct BlackjackCardTests {
  @Test internal func testBlackjackCardExample() throws {
    let blackjackCard = Struct("BlackjackCard") {
      Enum("Suit") {
        EnumCase("spades").equals("♠")
        EnumCase("hearts").equals("♡")
        EnumCase("diamonds").equals("♢")
        EnumCase("clubs").equals("♣")
      }.inherits("Character")
    }

    let expected = """
      struct BlackjackCard {
        enum Suit: Character {
          case spades = "♠"
          case hearts = "♡"
          case diamonds = "♢"
          case clubs = "♣"
        }
      }
      """

    // Normalize whitespace, remove comments and modifiers, and normalize colon spacing
    let normalizedGenerated = blackjackCard.syntax.description.normalize()

    let normalizedExpected = expected.normalize()

    #expect(normalizedGenerated == normalizedExpected)
  }
}
