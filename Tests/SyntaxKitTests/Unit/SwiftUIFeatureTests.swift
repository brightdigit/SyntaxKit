//
//  SwiftUIExampleTests.swift
//  SyntaxKitTests
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
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

@Suite internal struct SwiftUIFeatureTests {
  @Test("SwiftUI example DSL generates expected Swift code")
  internal func testSwiftUIExample() throws {
    // Test the onToggle variable with closure type and attributes
    let onToggleVariable = Variable(.let, name: "onToggle", type: "(Date) -> Void")
      .access("private")

    let generatedCode = onToggleVariable.generateCode()
    let expectedCode = "private let onToggle: (Date) -> Void"
    let normalizedGenerated = generatedCode.replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "\n", with: "")
    let normalizedExpected = expectedCode.replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "\n", with: "")
    #expect(normalizedGenerated == normalizedExpected)
  }

  @Test("SwiftUI example with complex closure and capture list")
  internal func testSwiftUIComplexClosure() throws {
    // Test the Task with closure that has capture list and attributes
    let taskClosure = Closure(
      capture: {
        ParameterExp(unlabeled: VariableExp("self"))
      },
      body: {
        VariableExp("self").call("onToggle") {
          ParameterExp(unlabeled: Init("Date"))
        }
      }
    )

    let generatedCode = taskClosure.generateCode()
    #expect(generatedCode.contains("self"))
    #expect(generatedCode.contains("onToggle"))
    #expect(generatedCode.contains("Date()"))
  }

  @Test("Method chaining on ConditionalOp")
  internal func testMethodChainingOnConditionalOp() throws {
    let conditional = ConditionalOp(
      if: VariableExp("item").property("isCompleted"),
      then: Literal.string("checkmark.circle.fill"),
      else: Literal.string("circle")
    )

    let methodCall = conditional.call("foregroundColor") {
      ParameterExp(unlabeled: EnumCase("green"))
    }

    let generated = methodCall.syntax.description
    #expect(generated.contains("foregroundColor"))
  }

  @Test("Reference method supports different reference types")
  internal func testReferenceMethodSupportsDifferentTypes() throws {
    // Test weak reference
    let weakRef = VariableExp("self").reference("weak")
    // The ReferenceExp itself just shows the base variable name
    let weakGenerated = weakRef.syntax.description
    #expect(weakGenerated.contains("self"))

    // Test unowned reference
    let unownedRef = VariableExp("self").reference("unowned")
    let unownedGenerated = unownedRef.syntax.description
    #expect(unownedGenerated.contains("self"))

    // Verify that the reference types are stored correctly
    if let weakRefExp = weakRef as? ReferenceExp {
      #expect(weakRefExp.captureReferenceType == "weak")
    } else {
      #expect(false, "Expected ReferenceExp type")
    }

    if let unownedRefExp = unownedRef as? ReferenceExp {
      #expect(unownedRefExp.captureReferenceType == "unowned")
    } else {
      #expect(false, "Expected ReferenceExp type")
    }
  }

  @Test("Reference method generates correct capture list syntax")
  internal func testReferenceMethodGeneratesCorrectCaptureList() throws {
    // Test weak reference in closure capture
    let weakClosure = Closure(
      capture: {
        ParameterExp(unlabeled: VariableExp("self").reference("weak"))
      },
      body: {
        VariableExp("self").optional().call("handleData") {
          ParameterExp(unlabeled: VariableExp("data"))
        }
      }
    )

    let weakGenerated = weakClosure.syntax.description
    print("Weak closure generated:\n\(weakGenerated)")
    #expect(weakGenerated.contains("[weak self]"))

    // Test unowned reference in closure capture
    let unownedClosure = Closure(
      capture: {
        ParameterExp(unlabeled: VariableExp("self").reference("unowned"))
      },
      body: {
        VariableExp("self").call("handleData") {
          ParameterExp(unlabeled: VariableExp("data"))
        }
      }
    )

    let unownedGenerated = unownedClosure.syntax.description
    print("Unowned closure generated:\n\(unownedGenerated)")
    #expect(unownedGenerated.contains("[unowned self]"))
  }
}
