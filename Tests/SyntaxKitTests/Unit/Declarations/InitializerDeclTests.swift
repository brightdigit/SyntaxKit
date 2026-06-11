//
//  InitializerDeclTests.swift
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

internal struct InitializerDeclTests {
  @Test internal func testEmptyInit() {
    let initDecl = InitializerDecl {}

    let expected = """
      init() {
      }
      """

    let normalizedGenerated = initDecl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testPublicInit() {
    let initDecl = InitializerDecl {}.access(.public)

    let expected = """
      public init() {
      }
      """

    let normalizedGenerated = initDecl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testThrowingInit() {
    let initDecl = InitializerDecl {}.throwing()

    let expected = """
      init() throws {
      }
      """

    let normalizedGenerated = initDecl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testAsyncInit() {
    let initDecl = InitializerDecl {}.async()

    let expected = """
      init() async {
      }
      """

    let normalizedGenerated = initDecl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testPublicInitWithBody() {
    let initDecl = InitializerDecl {
      Call("setup")
    }.access(.internal)

    let expected = """
      internal init() {
        setup()
      }
      """

    let normalizedGenerated = initDecl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }
}
