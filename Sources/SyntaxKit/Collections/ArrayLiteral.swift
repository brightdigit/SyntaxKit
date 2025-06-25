//
//  ArrayLiteral.swift
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

/// An array literal value that can be used as a literal.
internal struct ArrayLiteral: LiteralValue, CodeBlockable {
  internal let elements: [Literal]

  /// Creates an array with the given elements.
  /// - Parameter elements: The array elements.
  internal init(_ elements: [Literal]) {
    self.elements = elements
  }

  /// The code block representation of this array literal.
  internal var codeBlock: CodeBlock {
    Literal.array(elements)
  }

  /// The Swift type name for this array.
  internal var typeName: String {
    if elements.isEmpty {
      // TODO: Consider more specific type inference for empty arrays
      return "[Any]"
    }
    let elementType = elements.first?.typeName ?? "Any"
    return "[\(elementType)]"
  }

  /// Renders this array as a Swift literal string.
  internal var literalString: String {
    let elementStrings = elements.map { element in
      switch element {
      case .integer(let value): return String(value)
      case .float(let value): return String(value)
      case .string(let value): return "\"\(value)\""
      case .boolean(let value): return value ? "true" : "false"
      case .nil: return "nil"
      case .ref(let value): return value
      case .tuple(let tupleElements):
        let tuple = TupleLiteralArray(tupleElements)
        return tuple.literalString
      case .array(let arrayElements):
        let array = ArrayLiteral(arrayElements)
        return array.literalString
      case .dictionary(let dictionaryElements):
        let dictionary = DictionaryLiteral(dictionaryElements)
        return dictionary.literalString
      }
    }
    return "[\(elementStrings.joined(separator: ", "))]"
  }
}
