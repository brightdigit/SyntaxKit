//
//  ClosureParameter.swift
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

public import SwiftSyntax

/// Represents a parameter in a closure signature.
public struct ClosureParameter: TypeRepresentable {
  public var name: String
  public var type: String?
  internal var attributes: [AttributeInfo]

  public var typeSyntax: TypeSyntax {
    if let type = type {
      return TypeSyntax(IdentifierTypeSyntax(name: .identifier(type)))
    } else {
      return TypeSyntax(IdentifierTypeSyntax(name: .identifier("Any")))
    }
  }

  public init(_ name: String, type: String? = nil) {
    self.name = name
    self.type = type
    self.attributes = []
  }

  public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
    var copy = self
    copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
    return copy
  }
}
