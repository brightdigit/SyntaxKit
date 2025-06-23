import Foundation
import Testing

@testable import SyntaxKit

@Suite internal struct ConcurrencyExampleTests {
  @Test("Concurrency vending machine DSL generates expected Swift code")
  internal func testConcurrencyVendingMachineExample() throws {
    // Build DSL equivalent of Examples/Remaining/concurrency/dsl.swift
    // Note: This test includes the Item struct that's referenced but not defined in the original DSL

    let program = Group {
      // Item struct (needed for the vending machine)
      Struct("Item") {
        Variable(.let, name: "price", type: "Int").withExplicitType()
        Variable(.var, name: "count", type: "Int").withExplicitType()
      }

      // VendingMachineError enum
      Enum("VendingMachineError") {
        Case("invalidSelection")
        Case("insufficientFunds").associatedValue("coinsNeeded", type: "Int")
        Case("outOfStock")
      }
      .inherits("Error")

      // VendingMachine class
      Class("VendingMachine") {
        Variable(
          .var,
          name: "inventory",
          equals: DictionaryExpr([
            (
              Literal.string("Candy Bar"),
              Init("Item") {
                ParameterExp(name: "price", value: Literal.integer(12))
                ParameterExp(name: "count", value: Literal.integer(7))
              }
            ),
            (
              Literal.string("Chips"),
              Init("Item") {
                ParameterExp(name: "price", value: Literal.integer(10))
                ParameterExp(name: "count", value: Literal.integer(4))
              }
            ),
            (
              Literal.string("Pretzels"),
              Init("Item") {
                ParameterExp(name: "price", value: Literal.integer(7))
                ParameterExp(name: "count", value: Literal.integer(11))
              }
            ),
          ])
        )
        Variable(.var, name: "coinsDeposited", equals: 0)

        Function("vend") {
          Parameter("name", labeled: "itemNamed", type: "String")
        } _: {
          Guard {
            Let("item", "inventory[name]")
          } else: {
            Throw(VariableExp("VendingMachineError.invalidSelection"))
          }
          Guard {
            Infix(">") {
              VariableExp("item").property("count")
              Literal.integer(0)
            }
          } else: {
            Throw(VariableExp("VendingMachineError.outOfStock"))
          }
          Guard {
            Infix("<=") {
              VariableExp("item").property("price")
              VariableExp("coinsDeposited")
            }
          } else: {
            Throw(
              Call("VendingMachineError.insufficientFunds") {
                ParameterExp(
                  name: "coinsNeeded",
                  value: Infix("-") {
                    VariableExp("item").property("price")
                    VariableExp("coinsDeposited")
                  }
                )
              }
            )
          }
          Infix("-=") {
            VariableExp("coinsDeposited")
            VariableExp("item").property("price")
          }
          Variable(.var, name: "newItem", equals: Literal.ref("item"))
          Infix("-=") {
            VariableExp("newItem").property("count")
            Literal.integer(1)
          }
          Assignment("inventory[name]", .ref("newItem"))
          Call("print") {
            ParameterExp(unlabeled: "\"Dispensing \\(name)\"")
          }
        }
        .throws()
      }
    }

    // Expected Swift code from Examples/Remaining/concurrency/code.swift
    let expectedCode = """
      struct Item {
        let price: Int
        var count: Int
      }

      enum VendingMachineError: Error {
        case invalidSelection
        case insufficientFunds(coinsNeeded: Int)
        case outOfStock
      }

      class VendingMachine {
        var inventory = [
          "Candy Bar": Item(price: 12, count: 7),
          "Chips": Item(price: 10, count: 4),
          "Pretzels": Item(price: 7, count: 11)
        ]
        var coinsDeposited = 0

        func vend(itemNamed name: String) throws {
          guard let item = inventory[name] else {
            throw VendingMachineError.invalidSelection
          }

          guard item.count > 0 else {
            throw VendingMachineError.outOfStock
          }

          guard item.price <= coinsDeposited else {
            throw VendingMachineError.insufficientFunds(coinsNeeded: item.price - coinsDeposited)
          }

          coinsDeposited -= item.price

          var newItem = item
          newItem.count -= 1
          inventory[name] = newItem

          print("Dispensing \\(name)")
        }
      }
      """

    // Generate code from DSL
    let generated = program.generateCode().normalize()
    let expected = expectedCode.normalize()
    #expect(generated == expected)
  }

  func testSwiftUIDSLFeatures() throws {
    // Build the DSL for the SwiftUI example, matching Examples/Completed/swiftui/dsl.swift
    let dsl: [any CodeBlock] = [
      Import("SwiftUI").access("public"),
      Struct("TodoItemRow") {
        Variable(.let, name: "item", type: "TodoItem").access("private")
        Variable(
          .let,
          name: "onToggle",
          type: "(Date) -> Void"
        ).access("private")
        ComputedProperty("body", type: "some View") {
          Init("HStack") {
            ParameterExp(
              unlabeled: Closure {
                Init("Button") {
                  ParameterExp(name: "action", value: VariableExp("onToggle"))
                  ParameterExp(
                    unlabeled: Closure {
                      Init("Image") {
                        ParameterExp(
                          name: "systemName",
                          value:
                            FunctionCallExp(
                              baseName: "",
                              methodName: "foregroundColor",
                              parameters: [
                                ParameterExp(
                                  unlabeled: ConditionalOp(
                                    if: VariableExp("item").property("isCompleted"),
                                    then: EnumCase("green"),
                                    else: EnumCase("gray")
                                  )
                                )
                              ]
                            )
                        )
                      }
                    })
                }
                Init("Button") {
                  ParameterExp(
                    name: "action",
                    value: Closure {
                      Init("Task") {
                        ParameterExp(
                          unlabeled: Closure {
                            Call("print") {
                              ParameterExp(unlabeled: Literal.string("Task executed"))
                            }
                          }.attribute("@MainActor"))
                      }
                    })
                }
              })
          }
        }
      }
      .inherits("View")
      .access("public"),
    ]

    // Generate Swift code
    let generated = dsl.map { $0.syntax.description }.joined(separator: "\n\n")
    let expected = try String(contentsOfFile: "Examples/Completed/swiftui/code.swift")
    #expect(generated.trimmed == expected.trimmed)
  }
}

extension String {
  fileprivate var trimmed: String { self.trimmingCharacters(in: .whitespacesAndNewlines) }
}
