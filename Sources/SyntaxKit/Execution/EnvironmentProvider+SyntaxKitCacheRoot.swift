//
//  EnvironmentProvider+SyntaxKitCacheRoot.swift
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

internal import Foundation

/// Constants for `EnvironmentProvider.syntaxKitCacheRoot(default:)`. Nested
/// in a private enum to satisfy the "no globals" rule while letting the
/// protocol extension below reference them.
private enum SyntaxKitCacheRootConstants {
  /// Environment variable pointing at the XDG cache root, if set.
  static let xdgCacheHomeEnvKey = "XDG_CACHE_HOME"
  /// Leaf directory appended to the XDG cache root for skit's caches.
  static let cacheDirectoryName = "syntaxkit"
}

extension EnvironmentProvider {
  /// Root for all skit caches: `<XDG_CACHE_HOME>/syntaxkit` when that env
  /// var is set and non-empty, otherwise `defaultRoot` (typically the
  /// platform's home-relative cache dir).
  internal func syntaxKitCacheRoot(default defaultRoot: URL) -> URL {
    if let xdg = environment[SyntaxKitCacheRootConstants.xdgCacheHomeEnvKey], !xdg.isEmpty {
      return URL(fileURLWithPath: xdg)
        .appendingPathComponent(SyntaxKitCacheRootConstants.cacheDirectoryName)
    }
    return defaultRoot
  }
}
