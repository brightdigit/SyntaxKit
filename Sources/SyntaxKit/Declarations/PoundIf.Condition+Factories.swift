//
//  PoundIf.Condition+Factories.swift
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

extension PoundIf.Condition where Self == PoundIf.CanImport {
  /// `canImport(<module>)`
  /// - Parameter module: The module name to test for.
  /// - Returns: A `canImport` condition.
  public static func canImport(_ module: String) -> PoundIf.CanImport {
    .init(module: module)
  }
}

extension PoundIf.Condition where Self == PoundIf.Flag {
  /// A bare compilation flag such as `DEBUG`.
  /// - Parameter name: The flag identifier.
  /// - Returns: A flag condition.
  public static func flag(_ name: String) -> PoundIf.Flag {
    .init(name: name)
  }
}

extension PoundIf.Condition where Self == PoundIf.OSCheck {
  /// `os(<OperatingSystem>)`
  /// - Parameter value: The operating system to test for.
  /// - Returns: An `os` condition.
  public static func os(_ value: PoundIf.OperatingSystem) -> PoundIf.OSCheck {
    .init(value: value)
  }
}

extension PoundIf.Condition where Self == PoundIf.ArchCheck {
  /// `arch(<Architecture>)`
  /// - Parameter value: The CPU architecture to test for.
  /// - Returns: An `arch` condition.
  public static func arch(_ value: PoundIf.Architecture) -> PoundIf.ArchCheck {
    .init(value: value)
  }
}

extension PoundIf.Condition where Self == PoundIf.TargetEnvironmentCheck {
  /// `targetEnvironment(<TargetEnvironment>)`
  /// - Parameter value: The target environment to test for.
  /// - Returns: A `targetEnvironment` condition.
  public static func targetEnvironment(
    _ value: PoundIf.TargetEnvironment
  ) -> PoundIf.TargetEnvironmentCheck {
    .init(value: value)
  }
}

extension PoundIf.Condition where Self == PoundIf.SwiftCheck {
  /// `swift(>=5.9)` and friends.
  /// - Parameter check: The Swift language version comparison.
  /// - Returns: A `swift` version condition.
  public static func swift(_ check: PoundIf.VersionCheck) -> PoundIf.SwiftCheck {
    .init(check: check)
  }
}

extension PoundIf.Condition where Self == PoundIf.CompilerCheck {
  /// `compiler(>=5.9)` and friends.
  /// - Parameter check: The compiler version comparison.
  /// - Returns: A `compiler` version condition.
  public static func compiler(_ check: PoundIf.VersionCheck) -> PoundIf.CompilerCheck {
    .init(check: check)
  }
}

extension PoundIf.Condition where Self == PoundIf.HasFeature {
  /// `hasFeature(<name>)`
  /// - Parameter name: The feature name to test for.
  /// - Returns: A `hasFeature` condition.
  public static func hasFeature(_ name: String) -> PoundIf.HasFeature {
    .init(name: name)
  }
}

extension PoundIf.Condition where Self == PoundIf.HasAttribute {
  /// `hasAttribute(<name>)`
  /// - Parameter name: The attribute name to test for.
  /// - Returns: A `hasAttribute` condition.
  public static func hasAttribute(_ name: String) -> PoundIf.HasAttribute {
    .init(name: name)
  }
}

extension PoundIf.Condition where Self == PoundIf.And {
  /// `<lhs> && <rhs>`
  /// - Parameters:
  ///   - lhs: The left-hand condition.
  ///   - rhs: The right-hand condition.
  /// - Returns: A conjunction condition.
  public static func and<L: PoundIf.Condition, R: PoundIf.Condition>(
    _ lhs: L,
    _ rhs: R
  ) -> PoundIf.And {
    .init(lhs: lhs, rhs: rhs)
  }
}

extension PoundIf.Condition where Self == PoundIf.Or {
  /// `<lhs> || <rhs>`
  /// - Parameters:
  ///   - lhs: The left-hand condition.
  ///   - rhs: The right-hand condition.
  /// - Returns: A disjunction condition.
  public static func or<L: PoundIf.Condition, R: PoundIf.Condition>(
    _ lhs: L,
    _ rhs: R
  ) -> PoundIf.Or {
    .init(lhs: lhs, rhs: rhs)
  }
}

extension PoundIf.Condition where Self == PoundIf.Not {
  /// `!<operand>`
  /// - Parameter operand: The condition to negate.
  /// - Returns: A negation condition.
  public static func not<C: PoundIf.Condition>(_ operand: C) -> PoundIf.Not {
    .init(operand: operand)
  }
}
