//
//  PoundIf.VersionCheck.swift
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
