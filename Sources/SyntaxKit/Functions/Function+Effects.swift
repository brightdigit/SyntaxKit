//
//  Function+Effects.swift
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

extension Function {
  /// Function effect specifiers (async/throws combinations)
  internal enum Effect {
    case none
    /// synchronous effect specifier: throws or rethrows
    case `throws`(isRethrows: Bool, errorType: String?)
    case async
    /// combined async and throws/rethrows
    case asyncThrows(isRethrows: Bool, errorType: String?)
  }

  /// Marks the function as `throws` or `rethrows`.
  /// - Parameter isRethrows: Pass `true` to emit `rethrows` instead of `throws`.
  public func `throws`(isRethrows: Bool = false) -> Self {
    var copy = self
    switch effect {
    case .async:
      copy.effect = .asyncThrows(isRethrows: isRethrows, errorType: nil)
    default:
      copy.effect = .throws(isRethrows: isRethrows, errorType: nil)
    }
    return copy
  }

  /// Marks the function as `throws` with a specific error type.
  /// - Parameter errorType: The error type to specify in the throws clause.
  public func `throws`(_ errorType: String) -> Self {
    var copy = self
    switch effect {
    case .async:
      copy.effect = .asyncThrows(isRethrows: false, errorType: errorType)
    default:
      copy.effect = .throws(isRethrows: false, errorType: errorType)
    }
    return copy
  }

  /// Marks the function as `async`.
  public func async() -> Self {
    var copy = self
    copy.effect = .async
    return copy
  }

  /// Marks the function as `async throws` or `async rethrows`.
  /// - Parameter isRethrows: Pass `true` to emit `async rethrows`.
  public func asyncThrows(isRethrows: Bool = false) -> Self {
    var copy = self
    copy.effect = .asyncThrows(isRethrows: isRethrows, errorType: nil)
    return copy
  }

  /// Marks the function as `async throws` with a specific error type.
  /// - Parameter errorType: The error type to specify in the throws clause.
  public func asyncThrows(_ errorType: String) -> Self {
    var copy = self
    copy.effect = .asyncThrows(isRethrows: false, errorType: errorType)
    return copy
  }
}
