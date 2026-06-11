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

  @Test internal func testAsyncThrowingInit() {
    let initDecl = InitializerDecl {}.async().throwing()

    // Fix 2 regression: async and throws must be single-spaced, not "async  throws".
    let generated = initDecl.syntax.description
    #expect(generated.contains("async throws"))
    #expect(!generated.contains("async  throws"))

    let expected = """
      init() async throws {
      }
      """
    #expect(initDecl.generateCode().normalize() == expected.normalize())
  }

  @Test internal func testInitWithParameters() {
    let initDecl = InitializerDecl {
      Parameter(name: "name", type: "String")
      Parameter(name: "age", type: "Int")
    } _: {
      Call("print") {
        ParameterExp(unlabeled: Literal.string("hi"))
      }
    }

    let expected = """
      init(name: String, age: Int) {
        print("hi")
      }
      """

    let normalizedGenerated = initDecl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test internal func testInitWithParameterDefault() {
    let initDecl = InitializerDecl {
      Parameter(name: "count", type: "Int", defaultValue: "0")
    } _: {
    }

    let generated = initDecl.generateCode().normalize()
    #expect(generated.contains("count: Int = 0"))
  }

  @Test internal func testPublicInitWithParameters() {
    let initDecl = InitializerDecl {
      Parameter(name: "value", type: "String")
    } _: {
    }
    .access(.public)

    let expected = """
      public init(value: String) {
      }
      """

    let normalizedGenerated = initDecl.generateCode().normalize()
    let normalizedExpected = expected.normalize()
    #expect(normalizedGenerated == normalizedExpected)
  }
}
