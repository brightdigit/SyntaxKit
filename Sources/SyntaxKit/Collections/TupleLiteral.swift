//
//  TupleLiteral.swift
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

/// A tuple literal value that can be used as a literal.
public struct TupleLiteral: LiteralValue {
  public let elements: [Literal?]

  /// Creates a tuple with the given elements.
  /// - Parameter elements: The tuple elements, where `nil` represents a wildcard.
  public init(_ elements: [Literal?]) {
    self.elements = elements
  }

  /// The Swift type name for this tuple.
  public var typeName: String {
    let elementTypes = elements.map { element in
      if let element = element {
        switch element {
        case .integer: return "Int"
        case .float: return "Double"
        case .string: return "String"
        case .boolean: return "Bool"
        case .nil: return "Any?"
        case .ref: return "Any"
        case .tuple: return "Any"
        case .array: return "Any"
        case .dictionary: return "Any"
        }
      } else {
        return "Any"
      }
    }
    return "(\(elementTypes.joined(separator: ", ")))"
  }

  /// Renders this tuple as a Swift literal string.
  public var literalString: String {
    let elementStrings = elements.map { element in
      if let element = element {
        switch element {
        case .integer(let value): return String(value)
        case .float(let value): return String(value)
        case .string(let value): return "\"\(value)\""
        case .boolean(let value): return value ? "true" : "false"
        case .nil: return "nil"
        case .ref(let value): return value
        case .tuple(let tupleElements):
          let tuple = TupleLiteral(tupleElements)
          return tuple.literalString
        case .array(let arrayElements):
          let array = ArrayLiteral(arrayElements)
          return array.literalString
        case .dictionary(let dictionaryElements):
          let dictionary = DictionaryLiteral(dictionaryElements)
          return dictionary.literalString
        }
      } else {
        return "_"
      }
    }
    return "(\(elementStrings.joined(separator: ", ")))"
  }
}
