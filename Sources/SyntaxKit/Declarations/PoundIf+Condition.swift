//
//  PoundIf+Condition.swift
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
  // swiftlint:disable identifier_name

  /// Canonical `#if` checks, mirroring Swift's conditional-compilation grammar.
  public indirect enum Condition: Sendable {
    /// `canImport(<module>)`
    case canImport(String)
    /// A bare compilation flag such as `DEBUG`.
    case flag(String)
    /// `os(<OperatingSystem>)`
    case os(OperatingSystem)
    /// `arch(<Architecture>)`
    case arch(Architecture)
    /// `targetEnvironment(<TargetEnvironment>)`
    case targetEnvironment(TargetEnvironment)
    /// `swift(>=5.9)` and friends.
    case swift(VersionCheck)
    /// `compiler(>=5.9)` and friends.
    case compiler(VersionCheck)
    /// `hasFeature(<name>)`
    case hasFeature(String)
    /// `hasAttribute(<name>)`
    case hasAttribute(String)
    /// `<lhs> && <rhs>`
    case and(Condition, Condition)
    /// `<lhs> || <rhs>`
    case or(Condition, Condition)
    /// `!<operand>`
    case not(Condition)
  }

  // swiftlint:enable identifier_name

  /// Operating-system identifiers used in `os(...)` checks.
  public enum OperatingSystem: String, Sendable {
    /// `os(iOS)`
    case iOS
    /// `os(macOS)`
    case macOS
    /// `os(tvOS)`
    case tvOS
    /// `os(watchOS)`
    case watchOS
    /// `os(visionOS)`
    case visionOS
    /// `os(Linux)`
    case linux = "Linux"
    /// `os(Windows)`
    case windows = "Windows"
    /// `os(FreeBSD)`
    case freeBSD = "FreeBSD"
    /// `os(Android)`
    case android = "Android"
    /// `os(WASI)`
    case wasi = "WASI"
  }

  /// CPU-architecture identifiers used in `arch(...)` checks.
  public enum Architecture: String, Sendable {
    /// `arch(arm64)`
    case arm64
    /// `arch(x86_64)`
    case x86 = "x86_64"
    /// `arch(i386)`
    case i386
    /// `arch(arm)`
    case arm
    /// `arch(wasm32)`
    case wasm32
  }

  /// Target-environment identifiers used in `targetEnvironment(...)` checks.
  public enum TargetEnvironment: String, Sendable {
    /// `targetEnvironment(simulator)`
    case simulator
    /// `targetEnvironment(macCatalyst)`
    case macCatalyst
  }

  /// A `swift(>=5.9)` / `compiler(>=5.9)`-style version check.
  public struct VersionCheck: Sendable {
    /// The comparison operator used between the keyword and the version.
    public enum Comparison: String, Sendable {
      /// `>=`
      case greaterThanOrEqual = ">="
      /// `>`
      case greaterThan = ">"
      /// `<=`
      case lessThanOrEqual = "<="
      /// `<`
      case lessThan = "<"
      /// `==`
      case equal = "=="
    }

    /// The comparison operator that precedes the version.
    public let comparison: Comparison
    /// The major version component.
    public let major: Int
    /// The optional minor version component.
    public let minor: Int?
    /// The optional patch version component.
    public let patch: Int?

    internal var versionString: String {
      var result = String(major)
      if let minor = minor {
        result += ".\(minor)"
        if let patch = patch {
          result += ".\(patch)"
        }
      }
      return result
    }

    internal var rendered: String {
      "\(comparison.rawValue)\(versionString)"
    }

    /// Build a `>= major.minor[.patch]` check.
    public static func atLeast(_ major: Int, _ minor: Int? = nil, _ patch: Int? = nil)
      -> VersionCheck
    {
      VersionCheck(comparison: .greaterThanOrEqual, major: major, minor: minor, patch: patch)
    }

    /// Build an `== major.minor[.patch]` check.
    public static func exact(_ major: Int, _ minor: Int? = nil, _ patch: Int? = nil) -> VersionCheck
    {
      VersionCheck(comparison: .equal, major: major, minor: minor, patch: patch)
    }
  }
}
