//
//  DictionaryExpr.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import SwiftSyntax

/// A dictionary expression that can contain both Literal types and CodeBlock types.
public struct DictionaryExpr: CodeBlock, LiteralValue, CodeBlockable {
  private let elements: [(DictionaryValue, DictionaryValue)]

  /// Creates a dictionary expression with the given key-value pairs.
  /// - Parameter elements: The dictionary key-value pairs.
  public init(_ elements: [(DictionaryValue, DictionaryValue)]) {
    self.elements = elements
  }

  /// The code block representation of this dictionary expression.
  public var codeBlock: CodeBlock {
    self
  }

  /// The Swift type name for this dictionary.
  public var typeName: String {
    if elements.isEmpty {
      return "[Any: Any]"
    }
    return "[String: Any]"
  }

  /// Renders this dictionary as a Swift literal string.
  public var literalString: String {
    let elementStrings = elements.map { _, _ in
      let keyString: String
      let valueString: String

      // For now, we'll use a simple representation
      // In a real implementation, we'd need to convert DictionaryValue to string
      keyString = "key"
      valueString = "value"

      return "\(keyString): \(valueString)"
    }
    return "[\(elementStrings.joined(separator: ", "))]"
  }

  public var syntax: SyntaxProtocol {
    if elements.isEmpty {
      // Empty dictionary should generate [:]
      return DictionaryExprSyntax(
        leftSquare: .leftSquareToken(),
        content: .colon(.colonToken(leadingTrivia: .init(), trailingTrivia: .init())),
        rightSquare: .rightSquareToken()
      )
    } else {
      let dictionaryElements = DictionaryElementListSyntax(
        elements.enumerated().map { index, keyValue in
          let (key, value) = keyValue
          return DictionaryElementSyntax(
            key: key.exprSyntax,
            colon: .colonToken(),
            value: value.exprSyntax,
            trailingComma: index < elements.count - 1 ? .commaToken(trailingTrivia: .newline) : nil
          )
        }
      )
      return DictionaryExprSyntax(
        leftSquare: .leftSquareToken(trailingTrivia: .newline),
        content: .elements(dictionaryElements),
        rightSquare: .rightSquareToken(leadingTrivia: .newline)
      )
    }
  }
}
