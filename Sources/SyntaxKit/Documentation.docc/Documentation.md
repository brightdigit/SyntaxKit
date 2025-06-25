# ``SyntaxKit``

SyntaxKit provides a declarative way to generate Swift code structures using SwiftSyntax.

## Overview

SyntaxKit allows developers to build Swift code using result builders which enable the creation of Swift code structures in a declarative way. Here's an example:

```swift
import SyntaxKit

let code = Struct("BlackjackCard") {
    Enum("Suit") {
        EnumCase("spades").equals("♠")
        EnumCase("hearts").equals("♡")
        EnumCase("diamonds").equals("♢")
        EnumCase("clubs").equals("♣")
    }
    .inherits("Character")
    .comment("nested Suit enumeration")
}

let generatedCode = code.generateCode()
```

This will generate the following Swift code:

```swift
struct BlackjackCard {
    // nested Suit enumeration
    enum Suit: Character {
        case spades = "♠"
        case hearts = "♡"
        case diamonds = "♢"
        case clubs = "♣"
    }
}
```

## Full Example

Here is a more comprehensive example that demonstrates many of SyntaxKit's features to generate a `BlackjackCard` struct.

### DSL Code

```swift
import SyntaxKit

let structExample = Struct("BlackjackCard") {
    Enum("Suit") {
        EnumCase("spades").equals("♠")
        EnumCase("hearts").equals("♡")
        EnumCase("diamonds").equals("♢")
        EnumCase("clubs").equals("♣")
    }
    .inherits("Character")
    .comment("nested Suit enumeration")

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
        
        ComputedProperty("values") {
            Switch("self") {
                SwitchCase(".ace") {
                    Return {
                        Init("Values") {
                            Parameter(name: "first", value: "1")
                            Parameter(name: "second", value: "11")
                        }
                    }
                }
                SwitchCase(".jack", ".queen", ".king") {
                    Return {
                        Init("Values") {
                            Parameter(name: "first", value: "10")
                            Parameter(name: "second", value: "nil")
                        }
                    }
                }
                Default {
                    Return {
                        Init("Values") {
                            Parameter(name: "first", value: "self.rawValue")
                            Parameter(name: "second", value: "nil")
                        }
                    }
                }
            }
        }
    }
    .inherits("Int")
    .comment("nested Rank enumeration")

    Variable(.let, name: "rank", type: "Rank")
    Variable(.let, name: "suit", type: "Suit")
    .comment("BlackjackCard properties and methods")

    ComputedProperty("description") {
        VariableDecl(.var, name: "output", equals: "\"suit is \\(suit.rawValue),\"")
        PlusAssign("output", "\" value is \\(rank.values.first)\"")
        If(Let("second", "rank.values.second"), then: {
            PlusAssign("output", "\" or \\(second)\"")
        })
        Return {
            VariableExp("output")
        }
    }
}
```

### Generated Code

```swift
import Foundation

struct BlackjackCard {
  // nested Suit enumeration
  enum Suit: Character {
    case spades = "♠"
    case hearts = "♡"
    case diamonds = "♢"
    case clubs = "♣"
  }

  // nested Rank enumeration
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
      let first: Int, second: Int?
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

  // BlackjackCard properties and methods
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
```

## Topics

### Declarations

- ``Class``
- ``ComputedProperty``
- ``Enum``
- ``EnumCase``
- ``Extension``
- ``Function``
- ``Import``
- ``Init``
- ``Let``
- ``Protocol``
- ``Struct``
- ``Tuple``
- ``TypeAlias``
- ``Variable``

### Expressions & Statements
- ``Assignment``
- ``Call``
- ``Closure``
- ``ClosureParameter``
- ``ClosureType``
- ``ConditionalOp``
- ``Infix``
- ``PlusAssign``
- ``Return``
- ``Task``
- ``VariableExp``

### Control Flow
- ``Default``
- ``Do``
- ``For``
- ``Guard``
- ``If``
- ``Switch``
- ``SwitchCase``
- ``SwitchLet``
- ``While``

### Error Handling
- ``Catch``
- ``Throw``

### Collections
- ``ArrayLiteral``
- ``DictionaryExpr``
- ``DictionaryLiteral``
- ``TupleAssignment``
- ``TupleLiteral``
- ``TuplePattern``
- ``TuplePatternCodeBlock``

### Utilities
- ``Break``
- ``Case``
- ``Continue``
- ``Fallthrough``
- ``FunctionRequirement``
- ``Group``
- ``Parenthesized``
- ``PropertyRequirement``
- ``Then``

### Building Blocks
- ``Attribute``
- ``CodeBlock``
- ``EmptyCodeBlock``
- ``Line``
- ``Literal``
- ``Parameter``
- ``ParameterExp``

### Protocols
- ``CodeBlockable``
- ``CodeBlockBuilder``
- ``DictionaryValue``
- ``ExprCodeBlock``
- ``LiteralValue``
- ``PatternConvertible``
- ``TypeRepresentable``

### Result Builders
- ``CatchBuilder``
- ``ClosureParameterBuilderResult``
- ``CodeBlockBuilderResult``
- ``CommentBuilderResult``
- ``ExprCodeBlockBuilder``
- ``ParameterBuilderResult``
- ``ParameterExpBuilderResult``
- ``PatternConvertibleBuilder``

### Patterns
- ``LetBindingPattern``
- ``Pattern``

### Core Types
- ``AccessModifier``
- ``CaptureReferenceType``
- ``VariableKind``

