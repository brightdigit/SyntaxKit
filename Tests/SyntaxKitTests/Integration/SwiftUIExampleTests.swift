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
import SyntaxKit

@Suite internal struct SwiftUIExampleTests {
  @Test("SwiftUI example DSL generates expected Swift code")
  internal func testSwiftUIExample() throws {
    // Test the onToggle variable with closure type and attributes
    let onToggleVariable = Variable(.let, name: "onToggle", type: "(Date) -> Void")
      .access(.private)

    let generatedCode = onToggleVariable.generateCode()
    #expect(generatedCode.contains("private let onToggle"))
    #expect(generatedCode.contains("(Date) -> Void"))
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

  @Test("SwiftUI TodoItemRow DSL generates expected Swift code")
  internal func testSwiftUITodoItemRowExample() throws {
    // Use the full DSL from Examples/Completed/swiftui/dsl.swift
    let dsl = Group {
      Import("SwiftUI").access(.public)

      Struct("TodoItemRow") {
        Variable(.let, name: "item", type: "TodoItem").access(.private)

        Variable(
          .let,
          name: "onToggle",
          type:
            ClosureType(returns: "Void") {
              ClosureParameter("Date")
            }
            .attribute("MainActor")
            .attribute("Sendable")
        )
        .access(.private)

        ComputedProperty("body", type: "some View") {
          Init("HStack") {
            ParameterExp(
              unlabeled: Closure {
                ParameterExp(
                  unlabeled: Closure {
                    Init("Button") {
                      ParameterExp(name: "action", value: VariableExp("onToggle"))
                      ParameterExp(
                        unlabeled: Closure {
                          Init("Image") {
                            ParameterExp(
                              name: "systemName",
                              value: ConditionalOp(
                                if: VariableExp("item").property("isCompleted"),
                                then: Literal.string("checkmark.circle.fill"),
                                else: Literal.string("circle")
                              )
                            )
                          }.call("foregroundColor") {
                            ParameterExp(
                              unlabeled: ConditionalOp(
                                if: VariableExp("item").property("isCompleted"),
                                then: EnumCase("green"),
                                else: EnumCase("gray")
                              )
                            )
                          }
                        }
                      )
                    }
                    Init("Button") {
                      ParameterExp(
                        name: "action",
                        value: Closure {
                          Init("Task") {
                            ParameterExp(
                              unlabeled: Closure(
                                capture: {
                                  ParameterExp(unlabeled: VariableExp("self").reference(.weak))
                                },
                                body: {
                                  VariableExp("self").optional().call("onToggle") {
                                    ParameterExp(unlabeled: Init("Date"))
                                  }
                                }
                              )
                              .attribute("MainActor")
                            )
                          }
                        }
                      )
                      ParameterExp(
                        unlabeled: Closure {
                          Init("Image") {
                            ParameterExp(name: "systemName", value: Literal.string("trash"))
                          }
                        }
                      )
                    }
                  }
                )
              }
            )
          }
        }
        .access(.public)
      }
      .inherits("View")
      .access(.public)
    }

    // Expected Swift code from Examples/Completed/swiftui/code.swift
    let expectedCode = """
      public import SwiftUI

      public struct TodoItemRow: View {
        private let item: TodoItem
        private let onToggle: @MainActor @Sendable (Date) -> Void

        public var body: some View {
          HStack {
            Button(action: onToggle) {
              Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.isCompleted ? .green : .gray)
            }

            Button(action: {
              Task { @MainActor [weak self] in
                self?.onToggle(Date())
              }
            }) {
              Image(systemName: "trash")
            }
          }
        }
      }
      """

    // Generate code from DSL
    let generated = dsl.generateCode().normalizeFlexible()
    let expected = expectedCode.normalizeFlexible()
    #expect(generated == expected)
  }
}
