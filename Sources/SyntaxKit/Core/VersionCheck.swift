//
//  VersionCheck.swift
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

/// A `swift(>=5.9)` / `compiler(>=5.9)`-style version check pairing a
/// ``Comparison`` operator with a ``Version``.
public struct VersionCheck: Sendable {
  /// The comparison operator that precedes the version.
  public let comparison: Comparison
  /// The version the comparison is applied to.
  public let version: Version

  internal var rendered: String {
    "\(comparison.rawValue)\(version.versionString)"
  }

  /// Create a version check from a comparison and a version.
  /// - Parameters:
  ///   - comparison: The comparison operator that precedes the version.
  ///   - version: The version the comparison is applied to.
  public init(comparison: Comparison, version: Version) {
    self.comparison = comparison
    self.version = version
  }

  /// Build a `>= major.minor[.patch]` check.
  public static func greaterThanOrEqual(_ major: Int, _ minor: Int? = nil, _ patch: Int? = nil)
    -> VersionCheck
  {
    VersionCheck(comparison: .greaterThanOrEqual, version: Version(major, minor, patch))
  }

  /// Build a `> major.minor[.patch]` check.
  public static func greaterThan(_ major: Int, _ minor: Int? = nil, _ patch: Int? = nil)
    -> VersionCheck
  {
    VersionCheck(comparison: .greaterThan, version: Version(major, minor, patch))
  }

  /// Build a `<= major.minor[.patch]` check.
  public static func lessThanOrEqual(_ major: Int, _ minor: Int? = nil, _ patch: Int? = nil)
    -> VersionCheck
  {
    VersionCheck(comparison: .lessThanOrEqual, version: Version(major, minor, patch))
  }

  /// Build a `< major.minor[.patch]` check.
  public static func lessThan(_ major: Int, _ minor: Int? = nil, _ patch: Int? = nil)
    -> VersionCheck
  {
    VersionCheck(comparison: .lessThan, version: Version(major, minor, patch))
  }

  /// Build an `== major.minor[.patch]` check.
  public static func equal(_ major: Int, _ minor: Int? = nil, _ patch: Int? = nil) -> VersionCheck {
    VersionCheck(comparison: .equal, version: Version(major, minor, patch))
  }
}
