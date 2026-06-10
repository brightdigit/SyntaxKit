//
//  ContentHasherTests.swift
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
import Testing

@testable import SyntaxKit

@Suite internal struct ContentHasherTests {
  /// The FNV-1a offset basis, as the 16-char hex an empty hasher must finalize to.
  private static let emptyDigest = "cbf29ce484222325"

  private func digest(of data: Data) -> String {
    var hasher = ContentHasher()
    hasher.update(data: data)
    return hasher.finalize()
  }

  @Test("Empty input finalizes to the FNV-1a offset basis")
  internal func emptyInputDigest() {
    let hasher = ContentHasher()
    #expect(hasher.finalize() == Self.emptyDigest)
    #expect(digest(of: Data()) == Self.emptyDigest)
  }

  @Test("Same bytes produce the same digest across fresh hashers")
  internal func determinism() {
    let data = Data("the quick brown fox".utf8)
    let first = digest(of: data)
    let second = digest(of: data)
    #expect(first == second)
  }

  @Test("Different inputs produce different digests")
  internal func distinctInputs() {
    #expect(digest(of: Data("alpha".utf8)) != digest(of: Data("beta".utf8)))
  }

  @Test("Byte order is significant")
  internal func orderSensitivity() {
    #expect(digest(of: Data([0x01, 0x02])) != digest(of: Data([0x02, 0x01])))
  }

  @Test("Chunked updates accumulate identically to a single update")
  internal func chunkedAccumulation() {
    var chunked = ContentHasher()
    chunked.update(data: Data("AB".utf8))
    chunked.update(data: Data("C".utf8))

    #expect(chunked.finalize() == digest(of: Data("ABC".utf8)))
  }
}
