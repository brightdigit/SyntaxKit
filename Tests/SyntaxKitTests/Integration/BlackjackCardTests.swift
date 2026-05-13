//
//  BlackjackCardTests.swift
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

import SyntaxKit
import Testing

@Suite
internal struct BlackjackCardTests {
  @Test internal func testBlackjackCardExample() throws {
    let blackjackCard = Struct("BlackjackCard") {
      Enum("Suit") {
        EnumCase("spades").equals("♠")
        EnumCase("hearts").equals("♡")
        EnumCase("diamonds").equals("♢")
        EnumCase("clubs").equals("♣")
      }.inherits("Character")
    }

    let expected = """
      struct BlackjackCard {
        enum Suit: Character {
          case spades = "♠"
          case hearts = "♡"
          case diamonds = "♢"
          case clubs = "♣"
        }
      }
      """

    // Normalize whitespace, remove comments and modifiers, and normalize colon spacing
    let normalizedGenerated = blackjackCard.syntax.description.normalize()

    let normalizedExpected = expected.normalize()

    #expect(normalizedGenerated == normalizedExpected)
  }
}
