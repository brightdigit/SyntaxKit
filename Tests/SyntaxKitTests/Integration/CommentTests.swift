//
//  CommentTests.swift
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
import SyntaxKit
import Testing

internal struct CommentTests {
  @Test internal func testCommentInjection() {
    let syntax = Group {
      Struct("Card") {
        Variable(.let, name: "rank", type: "Rank")
          .comment {
            Line(.doc, "The rank of the card (2-10, J, Q, K, A)")
          }
        Variable(.let, name: "suit", type: "Suit")
          .comment {
            Line(.doc, "The suit of the card (hearts, diamonds, clubs, spades)")
          }
      }
      .inherits("Comparable")
      .comment {
        Line("MARK: - Models")
        Line(.doc, "Represents a playing card in a standard 52-card deck")
        Line(.doc)
        Line(
          .doc,
          "A card has a rank (2-10, J, Q, K, A) and a suit "
            + "(hearts, diamonds, clubs, spades)."
        )
        Line(.doc, "Each card can be compared to other cards based on its rank.")
      }

      Enum("Rank") {
        EnumCase("two").equals(2)
        EnumCase("three")
        EnumCase("four")
        EnumCase("five")
        EnumCase("six")
        EnumCase("seven")
        EnumCase("eight")
        EnumCase("nine")
        EnumCase("ten")
        EnumCase("jack")
        EnumCase("queen")
        EnumCase("king")
        EnumCase("ace")
        Struct("Values") {
          Variable(.let, name: "first", type: "Int")
          Variable(.let, name: "second", type: "Int?")
        }
        ComputedProperty("description", type: "String") {
          Switch("self") {
            SwitchCase(".jack") {
              Return {
                Literal.string("J")
              }
            }
            SwitchCase(".queen") {
              Return {
                Literal.string("Q")
              }
            }
            SwitchCase(".king") {
              Return {
                Literal.string("K")
              }
            }
            SwitchCase(".ace") {
              Return {
                Literal.string("A")
              }
            }
            Default {
              Return {
                Literal.string("\\(rawValue)")
              }
            }
          }
        }
        .comment {
          Line(.doc, "Returns a string representation of the rank")
        }
      }
      .inherits("Int")
      .inherits("CaseIterable")
      .comment {
        Line("MARK: - Enums")
        Line(.doc, "Represents the possible ranks of a playing card")
      }

      Enum("Suit") {
        EnumCase("spades").equals("♠")
        EnumCase("hearts").equals("♡")
        EnumCase("diamonds").equals("♢")
        EnumCase("clubs").equals("♣")
      }
      .inherits("String")
      .inherits("CaseIterable")
      .comment {
        Line(.doc, "Represents the possible suits of a playing card")
      }
    }

    let generated = syntax.generateCode().trimmingCharacters(in: .whitespacesAndNewlines)

    #expect(!generated.isEmpty)
    //
    //        #expect(generated.contains("MARK: - Models"), "MARK line should be present in generated code")
    //        #expect(generated.contains("Foo struct docs"),
    //                "Doc comment line should be present in generated code")
    //        // Ensure the struct declaration itself is still correct
    //        #expect(generated.contains("struct Foo"))
    //        #expect(generated.contains("bar"), "Variable declaration should be present")
  }
}
