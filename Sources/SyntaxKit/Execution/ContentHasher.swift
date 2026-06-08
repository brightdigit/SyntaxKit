//
//  ContentHasher.swift
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

/// Non-cryptographic 64-bit FNV-1a hasher used to derive content-addressed
/// cache keys. The cache keys aren't security-critical — there's no
/// adversary trying to forge a collision — so we don't need a cryptographic
/// hash. 64 bits of output gives ~10⁻⁹ collision probability at 10⁶ cache
/// entries, which is well past anything we'll see in practice.
///
/// FNV-1a is deterministic across processes and platforms (unlike the Swift
/// stdlib `Hasher`, whose seed is randomized per-process) — that
/// determinism is what makes it usable as an on-disk cache key.
internal struct ContentHasher {
  private static let offsetBasis: UInt64 = 0xcbf2_9ce4_8422_2325
  private static let prime: UInt64 = 0x0000_0100_0000_01b3

  private var state: UInt64 = ContentHasher.offsetBasis

  internal mutating func update(data: Data) {
    for byte in data {
      state ^= UInt64(byte)
      state &*= ContentHasher.prime
    }
  }

  /// Returns the hash as a 16-char lowercase-hex string suitable for use as
  /// a directory name.
  internal func finalize() -> String {
    String(format: "%016x", state)
  }
}
