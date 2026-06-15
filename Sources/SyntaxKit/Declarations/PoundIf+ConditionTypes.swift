//
//  PoundIf+ConditionTypes.swift
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

extension PoundIf {
  /// `canImport(<module>)`
  public struct CanImport: LeafCondition {
    /// The module name passed to `canImport`.
    public let module: String
    /// The `canImport` keyword.
    public var keyword: String? { "canImport" }
    /// The module name rendered inside the parentheses.
    public var argument: String { module }
  }

  /// A bare compilation flag such as `DEBUG`.
  public struct Flag: LeafCondition {
    /// The flag identifier.
    public let name: String
    /// A flag has no keyword and renders bare.
    public var keyword: String? { nil }
    /// The flag identifier rendered as-is.
    public var argument: String { name }
  }

  /// `os(<OperatingSystem>)`
  public struct OSCheck: LeafCondition {
    /// The operating system being checked.
    public let value: OperatingSystem
    /// The `os` keyword.
    public var keyword: String? { "os" }
    /// The operating-system identifier rendered inside the parentheses.
    public var argument: String { value.rawValue }
  }

  /// `arch(<Architecture>)`
  public struct ArchCheck: LeafCondition {
    /// The CPU architecture being checked.
    public let value: Architecture
    /// The `arch` keyword.
    public var keyword: String? { "arch" }
    /// The architecture identifier rendered inside the parentheses.
    public var argument: String { value.rawValue }
  }

  /// `targetEnvironment(<TargetEnvironment>)`
  public struct TargetEnvironmentCheck: LeafCondition {
    /// The target environment being checked.
    public let value: TargetEnvironment
    /// The `targetEnvironment` keyword.
    public var keyword: String? { "targetEnvironment" }
    /// The environment identifier rendered inside the parentheses.
    public var argument: String { value.rawValue }
  }

  /// `swift(>=5.9)` and friends.
  public struct SwiftCheck: LeafCondition {
    /// The Swift language version check.
    public let check: VersionCheck
    /// The `swift` keyword.
    public var keyword: String? { "swift" }
    /// The version comparison rendered inside the parentheses.
    public var argument: String { check.rendered }
  }

  /// `compiler(>=5.9)` and friends.
  public struct CompilerCheck: LeafCondition {
    /// The compiler version check.
    public let check: VersionCheck
    /// The `compiler` keyword.
    public var keyword: String? { "compiler" }
    /// The version comparison rendered inside the parentheses.
    public var argument: String { check.rendered }
  }

  /// `hasFeature(<name>)`
  public struct HasFeature: LeafCondition {
    /// The upcoming/experimental feature name.
    public let name: String
    /// The `hasFeature` keyword.
    public var keyword: String? { "hasFeature" }
    /// The feature name rendered inside the parentheses.
    public var argument: String { name }
  }

  /// `hasAttribute(<name>)`
  public struct HasAttribute: LeafCondition {
    /// The attribute name.
    public let name: String
    /// The `hasAttribute` keyword.
    public var keyword: String? { "hasAttribute" }
    /// The attribute name rendered inside the parentheses.
    public var argument: String { name }
  }
}

// MARK: - Combinators

extension PoundIf {
  // swiftlint:disable type_name

  /// `<lhs> && <rhs>`
  public struct And: BinaryCondition {
    /// The left-hand operand.
    public let lhs: any Condition
    /// The right-hand operand.
    public let rhs: any Condition
    /// The `&&` operator.
    public var symbol: String { "&&" }
  }

  /// `<lhs> || <rhs>`
  public struct Or: BinaryCondition {
    /// The left-hand operand.
    public let lhs: any Condition
    /// The right-hand operand.
    public let rhs: any Condition
    /// The `||` operator.
    public var symbol: String { "||" }
  }

  // swiftlint:enable type_name

  /// `!<operand>`
  public struct Not: Condition {
    /// The condition being negated.
    public let operand: any Condition

    /// Render as `!operand`, with the operand parenthesized as needed.
    public func render(atTopLevel _: Bool) -> String {
      "!\(operand.render(atTopLevel: false))"
    }
  }
}
