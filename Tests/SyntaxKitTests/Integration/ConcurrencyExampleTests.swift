//
//  ConcurrencyExampleTests.swift
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

@Suite internal struct ConcurrencyExampleTests {
  @Test("Concurrency vending machine DSL generates expected Swift code")
  @available(*, deprecated, message: "Exercises deprecated Infix builder closure init")
  internal func testConcurrencyVendingMachineExample() throws {
    // Build DSL equivalent of Examples/Remaining/concurrency/dsl.swift
    // Note: This test includes the Item struct that's referenced but not defined in the original DSL

    let program = try Group {
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
      try Class("VendingMachine") {
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

        try Function("vend") {
          Parameter("name", labeled: "itemNamed", type: "String")
        } _: {
          Guard {
            Let("item", "inventory[name]")
          } else: {
            Throw(
              EnumCase("VendingMachineError.invalidSelection")
            )
          }
          try Guard {
            try Infix(">") {
              VariableExp("item").property("count")
              Literal.integer(0)
            }
          } else: {
            Throw(EnumCase("VendingMachineError.outOfStock"))
          }
          try Guard {
            try Infix("<=") {
              VariableExp("item").property("price")
              VariableExp("coinsDeposited")
            }
          } else: {
            Throw(
              try Call("VendingMachineError.insufficientFunds") {
                ParameterExp(
                  name: "coinsNeeded",
                  value: try Infix("-") {
                    VariableExp("item").property("price")
                    VariableExp("coinsDeposited")
                  }
                )
              }
            )
          }
          try Infix("-=") {
            VariableExp("coinsDeposited")
            VariableExp("item").property("price")
          }
          Variable(.var, name: "newItem", equals: Literal.ref("item"))
          try Infix("-=") {
            VariableExp("newItem").property("count")
            Literal.integer(1)
          }
          Assignment("inventory[name]", .ref("newItem"))
          Call("print") {
            ParameterExp(unlabeled: Literal.string("Dispensing \\(name)"))
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
}
