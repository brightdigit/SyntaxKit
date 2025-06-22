//
//  Parameter.swift
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
import SwiftParser
import SwiftSyntax

/// A parameter for a function or initializer.
public struct Parameter: CodeBlock {
  /// The internal parameter name that is visible inside the function body.
  internal let name: String

  /// The external argument label (first name) shown at call-sites.
  /// If `nil`, the label is identical to the internal name (single-name parameter).
  /// If the label is the underscore character "_", the parameter is treated as unnamed.
  internal let label: String?

  internal let type: String
  internal let defaultValue: String?

  /// Convenience flag – true when the parameter uses the underscore label.
  internal var isUnnamed: Bool { label == "_" }

  internal var attributes: [AttributeInfo] = []

  /// Creates an unlabeled parameter for function calls or initializers.
  /// - Parameter value: The value of the parameter.
  public init(unlabeled value: String) {
    self.name = ""
    self.label = "_"
    self.type = ""
    self.defaultValue = value
  }

  /// Adds an attribute to the parameter declaration.
  /// - Parameters:
  ///   - attribute: The attribute name (without the @ symbol).
  ///   - arguments: The arguments for the attribute, if any.
  /// - Returns: A copy of the parameter with the attribute added.
  public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
    var copy = self
    copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
    return copy
  }

  public var syntax: SyntaxProtocol {
    let callLabel = label ?? name

    if let defaultValue = defaultValue {
      return LabeledExprSyntax(
        label: .identifier(callLabel),
        colon: .colonToken(),
        expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(defaultValue)))
      )
    } else {
      return LabeledExprSyntax(
        label: .identifier(callLabel),
        colon: .colonToken(),
        expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(name)))
      )
    }
    // Note: If you want to support attributes in parameter syntax, you would need to
    // update the function signature generation in Function.swift to use these attributes.
  }

  /// Creates a single-name parameter (same label and internal name).
  public init(name: String, type: String, defaultValue: String? = nil) {
    self.name = name
    self.label = nil
    self.type = type
    self.defaultValue = defaultValue
  }

  /// Creates a two-name parameter where the external label differs from the internal name.
  /// Example: `Parameter("value", labeled: "forKey", type: "String")` maps to
  /// `forKey value: String` in the generated Swift.
  public init(
    _ internalName: String,
    labeled externalLabel: String,
    type: String,
    defaultValue: String? = nil
  ) {
    self.name = internalName
    self.label = externalLabel
    self.type = type
    self.defaultValue = defaultValue
  }

  /// Creates an unlabeled (anonymous) parameter using the underscore label.
  public init(unlabeled internalName: String, type: String, defaultValue: String? = nil) {
    self.name = internalName
    self.label = "_"
    self.type = type
    self.defaultValue = defaultValue
  }

  /// Deprecated: retains source compatibility with earlier API that used an `isUnnamed` flag.
  /// Prefer `Parameter(unlabeled:type:)` or the new labelled initialisers.
  @available(*, deprecated, message: "Use Parameter(unlabeled:type:) or Parameter(_:labeled:type:)")
  public init(name: String, type: String, defaultValue: String? = nil, isUnnamed: Bool) {
    if isUnnamed {
      self.init(unlabeled: name, type: type, defaultValue: defaultValue)
    } else {
      self.init(name: name, type: type, defaultValue: defaultValue)
    }
  }
}
