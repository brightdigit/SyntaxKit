//
//  ContentHashing.swift
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

public import Foundation

/// An incremental hasher used to derive `OutputCache` keys. Abstracted so the
/// cache's hashing is pluggable: inject a different conformer via
/// `OutputCache.init(…, makeHasher:)` to swap the algorithm (e.g. a
/// cryptographic digest) without touching the cache.
///
/// Two contractual requirements callers depend on, which the default
/// `ContentHasher` (FNV-1a) satisfies and a replacement must too:
/// - **Determinism across processes and platforms.** Keys are persisted to
///   disk and compared on later runs, so the same byte stream must always
///   produce the same digest. (The stdlib `Hasher` is unsuitable — it is
///   per-process seeded.)
/// - **A digest usable as a directory name.** `finalize()` returns a string
///   that is safe to use as a path component.
public protocol ContentHashing {
  /// Creates an empty hasher, ready to accept `update(data:)` calls.
  init()
  /// Mixes `data`'s bytes into the running digest. Order-significant.
  mutating func update(data: Data)
  /// Returns the final digest as a filesystem-safe string.
  func finalize() -> String
}
