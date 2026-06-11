//
//  ClassTests+Modifiers.swift
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

extension ClassTests {
  @Suite("Modifiers") internal struct Modifiers {
    @Test internal func testFinalClass() {
      let finalClass = Class("FinalClass") {
        Variable(.var, name: "value", type: "String").withExplicitType()
      }.final()

      let expected = """
        final class FinalClass {
          var value: String
        }
        """

      let normalizedGenerated = finalClass.generateCode().normalize()
      let normalizedExpected = expected.normalize()
      #expect(normalizedGenerated == normalizedExpected)
    }

    @Test internal func testFinalClassWithInheritanceAndGenerics() {
      let finalGenericClass = Class("FinalGenericClass") {
        Variable(.var, name: "value", type: "T").withExplicitType()
      }.generic("T").inherits("BaseClass").final()

      let expected = """
        final class FinalGenericClass<T>: BaseClass {
          var value: T
        }
        """

      let normalizedGenerated = finalGenericClass.generateCode().normalize()
      let normalizedExpected = expected.normalize()
      #expect(normalizedGenerated == normalizedExpected)
    }

    @Test internal func testPublicClass() {
      let publicClass = Class("AppModel") {}.access(.public)

      let expected = """
        public class AppModel {
        }
        """

      let normalizedGenerated = publicClass.generateCode().normalize()
      let normalizedExpected = expected.normalize()
      #expect(normalizedGenerated == normalizedExpected)
    }

    @Test internal func testPublicFinalClass() throws {
      let publicFinalClass = Class("AppModel") {}
        .attribute("Observable")
        .access(.public)
        .final()
        .inherits("Sendable")

      let generated = publicFinalClass.generateCode()
      // Fix 2 regression: Class must support .access()
      #expect(generated.contains("public"))
      #expect(generated.contains("final"))
      #expect(generated.contains("class AppModel"))
      #expect(generated.contains("Sendable"))
      // Access modifier must precede final
      let publicRange = try #require(generated.range(of: "public"))
      let finalRange = try #require(generated.range(of: "final"))
      #expect(publicRange.lowerBound < finalRange.lowerBound)
    }

    @Test internal func testInternalClass() {
      let internalClass = Class("MyClass") {}.access(.internal)

      let expected = """
        internal class MyClass {
        }
        """

      let normalizedGenerated = internalClass.generateCode().normalize()
      let normalizedExpected = expected.normalize()
      #expect(normalizedGenerated == normalizedExpected)
    }
  }
}
