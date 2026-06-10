//
//  URL+Reroot.swift
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

import Foundation

extension URL {
  /// Re-roots this URL from `base` onto `newBase`, preserving the relative
  /// subpath — e.g. `/in/sub/a.swift` re-rooted from `/in` onto `/out` becomes
  /// `/out/sub/a.swift`. Used to mirror an input tree into an output tree.
  ///
  /// - Precondition: `self` is located under `base` (its path is prefixed by
  ///   `base`'s). Callers that enumerate `base` satisfy this by construction.
  internal func rerooted(from base: URL, onto newBase: URL) -> URL {
    let relative = path.dropFirst(base.path.count + 1)
    return newBase.appendingPathComponent(String(relative))
  }
}
