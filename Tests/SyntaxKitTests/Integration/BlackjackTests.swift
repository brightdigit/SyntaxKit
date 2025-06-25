import Testing

@testable import SyntaxKit

internal struct BlackjackTests {
  @Test internal func testBlackjackCardExample() throws {
    let syntax = Struct("BlackjackCard") {
      Enum("Suit") {
        EnumCase("spades").equals("♠")
        EnumCase("hearts").equals("♡")
        EnumCase("diamonds").equals("♢")
        EnumCase("clubs").equals("♣")
      }
      .inherits("Character")

      Enum("Rank") {
        EnumCase("two").equals(2)
        EnumCase("three")
        EnumCase("four")
        EnumCase("five")
        EnumCase("six")
        EnumCase("seven")
        EnumCase("eight")
        EnumCase("nine")
        EnumCase("ten")
        EnumCase("jack")
        EnumCase("queen")
        EnumCase("king")
        EnumCase("ace")
      }
      .inherits("Int")

      Variable(.let, name: "rank", type: "Rank")
      Variable(.let, name: "suit", type: "Suit")
    }

    let expected = """
      struct BlackjackCard {
        enum Suit: Character {
          case spades = "♠"
          case hearts = "♡"
          case diamonds = "♢"
          case clubs = "♣"
        }
        enum Rank: Int {
          case two = 2
          case three
          case four
          case five
          case six
          case seven
          case eight
          case nine
          case ten
          case jack
          case queen
          case king
          case ace
        }
        let rank: Rank
        let suit: Suit
      }
      """

    // Use structural comparison to focus on code structure rather than formatting
    let normalizedGenerated = syntax.syntax.description.normalizeStructural()
    let normalizedExpected = expected.normalizeStructural()

    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testFullBlackjackCardExample() throws {
    let syntax = Struct("BlackjackCard") {
      Enum("Suit") {
        EnumCase("spades").equals("♠")
        EnumCase("hearts").equals("♡")
        EnumCase("diamonds").equals("♢")
        EnumCase("clubs").equals("♣")
      }
      .inherits("Character")

      Enum("Rank") {
        EnumCase("two").equals(2)
        EnumCase("three")
        EnumCase("four")
        EnumCase("five")
        EnumCase("six")
        EnumCase("seven")
        EnumCase("eight")
        EnumCase("nine")
        EnumCase("ten")
        EnumCase("jack")
        EnumCase("queen")
        EnumCase("king")
        EnumCase("ace")
        Struct("Values") {
          Variable(.let, name: "first", type: "Int")
          Variable(.let, name: "second", type: "Int?")
        }
        ComputedProperty("values", type: "Values") {
          Switch("self") {
            SwitchCase(".ace") {
              Return {
                Init("Values") {
                  ParameterExp(name: "first", value: Literal.integer(1))
                  ParameterExp(name: "second", value: Literal.integer(11))
                }
              }
            }
            SwitchCase(".jack", ".queen", ".king") {
              Return {
                Init("Values") {
                  ParameterExp(name: "first", value: Literal.integer(10))
                  ParameterExp(name: "second", value: Literal.nil)
                }
              }
            }
            Default {
              Return {
                Init("Values") {
                  ParameterExp(name: "first", value: Literal.ref("self.rawValue"))
                  ParameterExp(name: "second", value: Literal.nil)
                }
              }
            }
          }
        }
      }
      .inherits("Int")

      Variable(.let, name: "rank", type: "Rank")
      Variable(.let, name: "suit", type: "Suit")
      ComputedProperty("description", type: "String") {
        Variable(.var, name: "output", equals: Literal.string("suit is \\(suit.rawValue),"))
        PlusAssign("output", " value is \\(rank.values.first)")
        If(
          Let("second", "rank.values.second"),
          then: {
            PlusAssign("output", " or \\(second)")
          }
        )
        Return {
          VariableExp("output")
        }
      }
    }

    let expected = """
      struct BlackjackCard {
        enum Suit: Character {
          case spades = "♠"
          case hearts = "♡"
          case diamonds = "♢"
          case clubs = "♣"
        }

        enum Rank: Int {
          case two = 2
          case three
          case four
          case five
          case six
          case seven
          case eight
          case nine
          case ten
          case jack
          case queen
          case king
          case ace

          struct Values {
            let first: Int
            let second: Int?
          }

          var values: Values {
            switch self {
            case .ace:
              return Values(first: 1, second: 11)
            case .jack, .queen, .king:
              return Values(first: 10, second: nil)
            default:
              return Values(first: self.rawValue, second: nil)
            }
          }
        }

        let rank: Rank
        let suit: Suit
        var description: String {
          var output = "suit is \\(suit.rawValue),"
          output += " value is \\(rank.values.first)"
          if let second = rank.values.second {
            output += " or \\(second)"
          }
          return output
        }
      }
      """

    // Use structural comparison to focus on code structure rather than formatting
    let normalizedGenerated = syntax.syntax.description.normalizeStructural()
    let normalizedExpected = expected.normalizeStructural()

    #expect(normalizedGenerated == normalizedExpected)
  }
}
