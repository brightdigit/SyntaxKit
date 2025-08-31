# SyntaxKit

**Generate Swift code dynamically, not statically.** SyntaxKit is a Swift package designed for scenarios where you need to create Swift code at compile-time or runtime—macro development, API client generators, model transformers, and migration utilities. If you're writing code you could write by hand once, stick with regular Swift. If you're generating repetitive code structures, transforming APIs into Swift models, or building developer tools that create Swift code, SyntaxKit provides a type-safe, declarative way to do it.

Unlike manually writing SwiftSyntax AST nodes, SyntaxKit uses result builders to make code generation readable and maintainable. Perfect for macro authors who need to generate complex Swift structures, or developers building tools that automatically create boilerplate code from external schemas, APIs, or configurations.

**When to choose SyntaxKit:** You're building a Swift macro, generating code from OpenAPI specs, creating model layers from databases, or building developer tools that output Swift code. **When to choose regular Swift:** You're writing application logic, view controllers, or any code you'd normally type by hand.

SyntaxKit transforms this complex task into declarative, readable code generation—making macro development and code generation tools significantly more approachable for Swift developers.

## When to Use SyntaxKit

```mermaid
graph TD
    A[Need to generate Swift code?] --> B{Code generation frequency?}
    B -->|One-time/Static| C[Write Swift manually]
    B -->|Repetitive/Dynamic| D{What type of generation?}
    
    D -->|Swift Macros| E[✅ Perfect for SyntaxKit]
    D -->|API Client from Schema| F[✅ Ideal SyntaxKit use case]
    D -->|Model/Entity Generation| G[✅ Great SyntaxKit fit]
    D -->|Developer Tools| H[✅ SyntaxKit recommended]
    D -->|App Logic/UI| I[❌ Use regular Swift]
    
    style E fill:#22c55e,stroke:#16a34a,color:#ffffff
    style F fill:#22c55e,stroke:#16a34a,color:#ffffff
    style G fill:#22c55e,stroke:#16a34a,color:#ffffff
    style H fill:#22c55e,stroke:#16a34a,color:#ffffff
    style I fill:#ef4444,stroke:#dc2626,color:#ffffff
    style C fill:#6b7280,stroke:#4b5563,color:#ffffff
```

**✅ Choose SyntaxKit when:**
- Building Swift macros or compiler plugins
- Generating Swift code from external schemas (OpenAPI, GraphQL, databases)
- Creating developer tools that output Swift code
- Building code generators or transformers
- Need type-safe programmatic Swift code construction

**❌ Use regular Swift when:**
- Writing application business logic
- Creating UI components or view controllers  
- Building standard iOS/macOS app features
- Code you'd write once and maintain manually

[![](https://img.shields.io/badge/docc-read_documentation-blue)](https://swiftpackageindex.com/brightdigit/SyntaxKit/documentation)
[![SwiftPM](https://img.shields.io/badge/SPM-Linux%20%7C%20iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-success?logo=swift)](https://swift.org)
![GitHub](https://img.shields.io/github/license/brightdigit/SyntaxKit)
![GitHub issues](https://img.shields.io/github/issues/brightdigit/SyntaxKit)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/brightdigit/SyntaxKit/SyntaxKit.yml?label=actions&logo=github&?branch=main)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrightdigit%2FSyntaxKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/brightdigit/SyntaxKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrightdigit%2FSyntaxKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/brightdigit/SyntaxKit)

[![Codecov](https://img.shields.io/codecov/c/github/brightdigit/SyntaxKit)](https://codecov.io/gh/brightdigit/SyntaxKit)
[![CodeFactor Grade](https://img.shields.io/codefactor/grade/github/brightdigit/SyntaxKit)](https://www.codefactor.io/repository/github/brightdigit/SyntaxKit)
[![codebeat badge](https://codebeat.co/badges/ad53f31b-de7a-4579-89db-d94eb57dfcaa)](https://codebeat.co/projects/github-com-brightdigit-SyntaxKit-main)
[![Maintainability](https://qlty.sh/badges/55637213-d307-477e-a710-f9dba332d955/maintainability.svg)](https://qlty.sh/gh/brightdigit/projects/SyntaxKit)

SyntaxKit provides a declarative way to generate Swift code structures using SwiftSyntax.

## Installation

Add SyntaxKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/brightdigit/SyntaxKit.git", from: "0.0.1")
]
```

## Usage

SyntaxKit provides a set of result builders that allow you to create Swift code structures in a declarative way. Here's an example:

```swift
import SyntaxKit

let code = Struct("BlackjackCard") {
    Enum("Suit") {
        Case("spades").equals("♠")
        Case("hearts").equals("♡")
        Case("diamonds").equals("♢")
        Case("clubs").equals("♣")
    }
    .inherits("Character")
    .comment{
      Line("nested Suit enumeration")
    }
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

## Features

- Create structs, enums, and cases using result builders
- Add inheritance and comments to your code structures
- Generate formatted Swift code using SwiftSyntax
- Type-safe code generation

## Requirements

- Swift 6.1+
- macOS 13.0+

## License

This project is licensed under the MIT License - [see the LICENSE file for details.](LICENSE)
