# ``SyntaxKit``

**Generate Swift code programmatically with declarative, type-safe syntax.** 

SyntaxKit transforms complex Swift code generation from tedious AST manipulation into intuitive, readable declarations. Built for scenarios where you need to create Swift code dynamically—macro development, API client generators, model transformers, and migration utilities—rather than writing code by hand once.

## Overview

**When you're generating repetitive code structures, transforming external schemas into Swift types, or building developer tools that output Swift code, SyntaxKit provides the declarative approach you need.** Unlike manually constructing SwiftSyntax AST nodes, SyntaxKit uses result builders to make complex code generation maintainable and error-resistant.

Perfect for macro authors who need to generate intricate Swift structures, developers building tools that automatically create boilerplate from APIs or databases, and teams creating migration utilities that transform data models. If you're writing application logic or view controllers—code you'd normally type by hand—stick with regular Swift. If you're programmatically generating Swift code structures, SyntaxKit is designed for you.

**Core scenarios where SyntaxKit excels:**
- **Swift Macro Development**: Replace complex AST manipulation with declarative macro logic
- **API Client Generation**: Transform OpenAPI specs into type-safe Swift networking code  
- **Model Generation**: Convert database schemas or JSON into Swift data models with computed properties
- **Migration Utilities**: Build tools that automatically transform legacy code structures
- **Developer Tools**: Create code generators for repetitive patterns and boilerplate

## When to Use SyntaxKit vs Raw Swift

**Choose SyntaxKit when you're generating Swift code programmatically. Choose raw Swift when you're writing application logic.**

| Scenario | Use SyntaxKit ✅ | Use Raw Swift ❌ | Why |
|----------|------------------|-------------------|-----|
| **Swift Macros** | Always | Never | Declarative syntax dramatically simplifies AST manipulation |
| **API Client Generation** | Yes | No | Transform OpenAPI specs into hundreds of type-safe endpoints |
| **Model Generation** | Yes | No | Convert schemas into Swift models with computed properties |
| **Migration Tools** | Yes | No | Build utilities that transform legacy code structures |
| **Code Templates** | Yes | No | Generate repetitive patterns from configurations |
| **Application Logic** | No | Always | Business logic, view controllers, standard app features |
| **One-time Scripts** | No | Maybe | Simple, write-once utilities don't need generation |
| **Performance-Critical** | No | Yes | Raw Swift avoids generation overhead |

### Decision Flow

```
Need to create Swift code?
├─ Will you write this code once by hand? → Use Raw Swift
└─ Will you generate this code programmatically?
   ├─ Building macros or compiler plugins? → Use SyntaxKit  
   ├─ Transforming external schemas/APIs? → Use SyntaxKit
   ├─ Creating developer tools? → Use SyntaxKit
   └─ Writing app business logic? → Use Raw Swift
```

**Key Questions:**
- Am I writing code that transforms data into Swift structures?
- Will this code be generated multiple times or from external inputs?
- Do I need type-safe programmatic Swift construction?

**If yes to any:** Use SyntaxKit. **If no to all:** Use raw Swift.

> 🚀 **Ready to start?** Follow our step-by-step <doc:Creating-Macros-with-SyntaxKit> tutorial to build your first macro in 15 minutes.

Here's a simple example showing SyntaxKit's declarative approach:

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

## Macro Development Showcase

**SyntaxKit transforms complex macro development from error-prone AST manipulation into maintainable, declarative code.** Here are compelling before/after comparisons showing how SyntaxKit simplifies common macro patterns.

### StringifyMacro Example

**Traditional SwiftSyntax Approach (Complex AST manipulation):**
```swift
public import SwiftSyntaxMacros
public import SwiftSyntax

struct StringifyMacro: ExpressionMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            throw StringifyError.missingArgument
        }
        
        // Complex AST node construction
        let stringLiteral = StringLiteralExprSyntax(
            openDelimiter: .stringQuoteToken(),
            segments: StringLiteralSegmentsSyntax([
                .stringSegment(StringSegmentSyntax(
                    content: .stringSegment(argument.description)
                ))
            ]),
            closeDelimiter: .stringQuoteToken()
        )
        
        return ExprSyntax(stringLiteral)
    }
}
```

**SyntaxKit Approach (Clean and declarative):**
```swift
import SyntaxKit
public import SwiftSyntaxMacros

struct StringifyMacro: ExpressionMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            throw StringifyError.missingArgument
        }
        
        // Declarative string literal generation
        return Literal(argument.description).expressionSyntax
    }
}
```

### Member Generation Macro

**Traditional Approach (80+ lines of complex node manipulation):**
```swift
struct MembersMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Complex variable extraction logic
        let variables = try extractStoredProperties(from: declaration)
        
        // Manual AST construction for each member
        var members: [DeclSyntax] = []
        
        // Manually build init function AST
        let initParams = ParameterClauseSyntax(
            parameterList: FunctionParameterListSyntax(
                variables.map { variable in
                    FunctionParameterSyntax(
                        firstName: .identifier(variable.name),
                        type: variable.type
                    )
                }
            )
        )
        // ... 60+ more lines of AST construction
        
        return members
    }
}
```

**SyntaxKit Approach (Clean and readable):**
<!-- example-only -->
```swift
struct MembersMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let variables = try extractStoredProperties(from: declaration)
        
        // Declarative member generation
        let members = Group {
            // Generate memberwise initializer
            Function("init") {
                for variable in variables {
                    Parameter(variable.name, type: variable.type)
                }
            }
            .body {
                for variable in variables {
                    Assignment("self.\(variable.name)", variable.name)
                }
            }
            
            // Generate description computed property
            ComputedProperty("description", type: "String") {
                Return {
                    Literal("\\(Self.self)(\\(variables.map { "\\($0.name): \\(\\($0.name))" }.joined(separator: ", ")))")
                }
            }
        }
        
        return members.memberDeclListSyntax.map(\.declSyntax)
    }
}
```

### Accessor Generation Macro

**Traditional Approach:**
```swift
// 100+ lines of complex accessor node construction
// involving TokenSyntax manipulation, CodeBlockSyntax creation,
// and manual getter/setter AST building...
```

**SyntaxKit Approach:**
```swift
struct AccessorMacro: AccessorMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self) else {
            throw AccessorError.notAProperty
        }
        
        // Declarative accessor generation
        let accessors = Group {
            Accessor(.get) {
                Return {
                    Call("_\(property.name).wrappedValue")
                }
            }
            
            Accessor(.set) {
                Assignment("_\(property.name).wrappedValue", "newValue")
            }
        }
        
        return accessors.accessorDeclListSyntax
    }
}
```

**Result:** SyntaxKit reduces macro complexity by 60-80%, improves readability, and eliminates most AST manipulation errors.

> 📖 **Learn macro development:** Our comprehensive <doc:Creating-Macros-with-SyntaxKit> tutorial covers these patterns and more advanced techniques.

## Performance Considerations

**SyntaxKit optimizes for developer productivity and code maintainability, with minimal runtime performance impact on generated code.**

### Compilation Time

| Aspect | Impact | Mitigation |
|--------|--------|------------|
| **Build Time** | +5-15% for macro compilation | SyntaxKit compilation is one-time cost |
| **Code Generation** | Negligible runtime overhead | Generated code is standard Swift |
| **SwiftSyntax Dependency** | Larger binary size during development | Not included in final app binaries |

### Runtime Performance

**Generated code performance is identical to hand-written Swift.** SyntaxKit operates at compile-time only:

```swift
// SyntaxKit-generated code
struct User: Equatable {
    let id: UUID
    let name: String
}

// Hand-written code  
struct User: Equatable {
    let id: UUID
    let name: String
}
```

Both compile to identical machine code with zero performance difference.

### Memory Usage

- **Development**: SwiftSyntax increases memory usage during compilation
- **Production**: No memory overhead—SyntaxKit isn't included in final binaries
- **Code Generation**: Uses standard Swift memory patterns

### When Performance Matters

**Choose SyntaxKit when:**
- Developer productivity outweighs small compilation time increases
- Generating complex, error-prone code structures
- Building macros or development tools
- Maintainability is more important than build speed

**Consider raw Swift when:**
- Extremely performance-sensitive build pipelines
- Simple, one-time code generation
- Minimal external dependencies required
- Team unfamiliar with result builder patterns

### Optimization Strategies

1. **Selective Usage**: Use SyntaxKit for complex generation, raw Swift for simple cases
2. **Caching**: Cache generated code structures when possible
3. **Lazy Generation**: Generate code on-demand rather than upfront
4. **Modular Design**: Break large generators into smaller, focused components

**Bottom Line:** SyntaxKit's compilation overhead is typically 5-15%, but saves hours of development time and prevents entire classes of AST manipulation errors.

> Important: SyntaxKit is designed for code generation scenarios. For standard application development, use regular Swift syntax.

## Topics

### Getting Started
- <doc:Creating-Macros-with-SyntaxKit>
- <doc:Best-Practices>

### Declarations
- ``AccessModifier``
- ``Class``
- ``ComputedProperty``
- ``Enum``
- ``Extension``
- ``Function``
- ``FunctionRequirement``
- ``Group``
- ``Import``
- ``Let``
- ``Parameter``
- ``PropertyRequirement``
- ``Protocol``
- ``Struct``
- ``Tuple``
- ``TypeAlias``
- ``Variable``
- ``VariableKind``

### Expressions & Statements
- ``Assignment``
- ``Call``
- ``CaptureReferenceType``
- ``Closure``
- ``ClosureParameter``
- ``ClosureType``
- ``ConditionalOp``
- ``EnumCase``
- ``Infix``
- ``Init``
- ``Line``
- ``Parenthesized``
- ``ParameterExp``
- ``PlusAssign``
- ``Return``
- ``VariableExp``

### Control Flow
- ``Break``
- ``Case``
- ``Continue``
- ``Default``
- ``Do``
- ``Fallthrough``
- ``For``
- ``Guard``
- ``If``
- ``Pattern``
- ``Switch``
- ``SwitchCase``
- ``SwitchLet``
- ``Then``
- ``While``

### Error Handling
- ``Catch``
- ``Throw``

### Building Blocks
- ``Attribute``
- ``CodeBlock``
- ``Literal``

### Protocols
- ``CodeBlockable``
- ``CodeBlockableLiteral``
- ``DictionaryValue``
- ``ExprCodeBlock``
- ``LiteralValue``
- ``PatternCodeBlock``
- ``PatternConvertible``
- ``TypeRepresentable``

### Result Builders
- ``CatchBuilder``
- ``ClosureParameterBuilderResult``
- ``CodeBlockBuilder``
- ``CodeBlockBuilderResult``
- ``CommentBuilderResult``
- ``ExprCodeBlockBuilder``
- ``ParameterBuilderResult``
- ``ParameterExpBuilderResult``
- ``PatternConvertibleBuilder``

> 💡 **Pro tip:** Most result builders are used automatically—focus on the type declarations and expressions above for your code generation needs.
