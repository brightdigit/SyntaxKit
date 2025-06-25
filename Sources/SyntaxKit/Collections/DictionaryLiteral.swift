//
//  DictionaryLiteral.swift
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

import Foundation

/// A dictionary literal value that can be used as a literal.
internal struct DictionaryLiteral: LiteralValue, CodeBlockable {
  internal let elements: [(Literal, Literal)]

  /// Creates a dictionary with the given key-value pairs.
  /// - Parameter elements: The dictionary key-value pairs.
  internal init(_ elements: [(Literal, Literal)]) {
    self.elements = elements
  }

  /// The code block representation of this dictionary literal.
  internal var codeBlock: CodeBlock {
    Literal.dictionary(elements)
  }

  /// The Swift type name for this dictionary.
  internal var typeName: String {
    if elements.isEmpty {
      return "[Any: Any]"
    }
    let keyType = elements.first?.0.typeName ?? "Any"
    let valueType = elements.first?.1.typeName ?? "Any"
    return "[\(keyType): \(valueType)]"
  }

  /// Renders this dictionary as a Swift literal string.
  internal var literalString: String {
    let elementStrings = elements.map { key, value in
      let keyString: String
      let valueString: String

      switch key {
      case .integer(let key): keyString = String(key)
      case .float(let key): keyString = String(key)
      case .string(let key): keyString = "\"\(key)\""
      case .boolean(let key): keyString = key ? "true" : "false"
      case .nil: keyString = "nil"
      case .ref(let key): keyString = key
      case .tuple(let tupleElements):
        let tuple = TupleLiteralArray(tupleElements)
        keyString = tuple.literalString
      case .array(let arrayElements):
        let array = ArrayLiteral(arrayElements)
        keyString = array.literalString
      case .dictionary(let dictionaryElements):
        let dictionary = DictionaryLiteral(dictionaryElements)
        keyString = dictionary.literalString
      }

      switch value {
      case .integer(let value): valueString = String(value)
      case .float(let value): valueString = String(value)
      case .string(let value): valueString = "\"\(value)\""
      case .boolean(let value): valueString = value ? "true" : "false"
      case .nil: valueString = "nil"
      case .ref(let value): valueString = value
      case .tuple(let tupleElements):
        let tuple = TupleLiteralArray(tupleElements)
        valueString = tuple.literalString
      case .array(let arrayElements):
        let array = ArrayLiteral(arrayElements)
        valueString = array.literalString
      case .dictionary(let dictionaryElements):
        let dictionary = DictionaryLiteral(dictionaryElements)
        valueString = dictionary.literalString
      }

      return "\(keyString): \(valueString)"
    }
    return "[\(elementStrings.joined(separator: ", "))]"
  }
}
