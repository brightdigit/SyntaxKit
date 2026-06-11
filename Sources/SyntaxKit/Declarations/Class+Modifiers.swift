//
//  Class+Modifiers.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

extension Class {
  /// Sets the generic parameters for the class.
  /// - Parameter generics: The list of generic parameter names.
  /// - Returns: A copy of the class with the generic parameters set.
  public func generic(_ generics: String...) -> Self {
    var copy = self
    copy.genericParameters = generics
    return copy
  }

  /// Sets the inheritance for the class.
  /// - Parameter inheritance: The types to inherit from.
  /// - Returns: A copy of the class with the inheritance set.
  public func inherits(_ inheritance: String...) -> Self {
    var copy = self
    copy.inheritance = inheritance
    return copy
  }

  /// Marks the class declaration as `final`.
  /// - Returns: A copy of the class marked as `final`.
  public func final() -> Self {
    var copy = self
    copy.isFinal = true
    return copy
  }

  /// Sets the access modifier for the class declaration.
  /// - Parameter access: The access modifier.
  /// - Returns: A copy of the class with the access modifier set.
  public func access(_ access: AccessModifier) -> Self {
    var copy = self
    copy.accessModifier = access
    return copy
  }

  /// Adds an attribute to the class declaration.
  /// - Parameters:
  ///   - attribute: The attribute name (without the @ symbol).
  ///   - arguments: The arguments for the attribute, if any.
  /// - Returns: A copy of the class with the attribute added.
  public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
    var copy = self
    copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
    return copy
  }
}
