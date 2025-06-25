//
//  CompleteProtocolsExampleTests.swift
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
import SyntaxKit
import Testing

@Suite internal struct CompleteProtocolsExampleTests {
  // MARK: - Helper Functions

  private func createProtocolsDSL() -> Group {
    Group {
      // MARK: - Protocol Definition
      Protocol("Vehicle") {
        PropertyRequirement("numberOfWheels", type: "Int", access: .get)
        PropertyRequirement("brand", type: "String", access: .get)
        FunctionRequirement("start")
        FunctionRequirement("stop")
      }
      .comment {
        Line("MARK: - Protocol Definition")
      }

      // MARK: - Protocol Extension
      Extension("Vehicle") {
        Function("start") {
          Call("print") {
            ParameterExp(name: "", value: "\"Starting \\(brand) vehicle...\"")
          }
        }

        Function("stop") {
          Call("print") {
            ParameterExp(name: "", value: "\"Stopping \\(brand) vehicle...\"")
          }
        }
      }
      .comment {
        Line("MARK: - Protocol Extension")
      }

      // MARK: - Protocol Composition
      Protocol("Electric") {
        PropertyRequirement("batteryLevel", type: "Double", access: .getSet)
        FunctionRequirement("charge")
      }
      .comment {
        Line("MARK: - Protocol Composition")
      }

      // MARK: - Concrete Types
      Struct("Car") {
        Variable(.let, name: "numberOfWheels", type: "Int", equals: 4).withExplicitType()
        Variable(.let, name: "brand", type: "String").withExplicitType()

        Function("start") {
          Call("print") {
            ParameterExp(name: "", value: "\"Starting \\(brand) car engine...\"")
          }
        }
      }
      .inherits("Vehicle")
      .comment {
        Line("MARK: - Concrete Types")
      }

      Struct("ElectricCar") {
        Variable(.let, name: "numberOfWheels", type: "Int", equals: 4).withExplicitType()
        Variable(.let, name: "brand", type: "String").withExplicitType()
        Variable(.var, name: "batteryLevel", type: "Double").withExplicitType()

        Function("charge") {
          Call("print") {
            ParameterExp(name: "", value: "\"Charging \\(brand) electric car...\"")
          }
          Assignment("batteryLevel", Literal.float(100.0))
        }
      }
      .inherits("Vehicle", "Electric")

      // MARK: - Usage Example
      Variable(
        .let,
        name: "tesla",
        equals: Init("ElectricCar") {
          ParameterExp(name: "brand", value: Literal.string("Tesla"))
          ParameterExp(name: "batteryLevel", value: Literal.float(75.0))
        }
      )
      .comment {
        Line("MARK: - Usage Example")
      }
      Variable(
        .let,
        name: "toyota",
        equals: Init("Car") {
          ParameterExp(name: "brand", value: Literal.string("Toyota"))
        }
      )

      // Demonstrate protocol usage
      Function("demonstrateVehicle") {
        Parameter(name: "vehicle", type: "Vehicle", isUnnamed: true)
      } _: {
        Call("print") {
          ParameterExp(name: "", value: "\"Vehicle brand: \\(vehicle.brand)\"")
        }
        Call("print") {
          ParameterExp(name: "", value: "\"Number of wheels: \\(vehicle.numberOfWheels)\"")
        }
        VariableExp("vehicle").call("start")
        VariableExp("vehicle").call("stop")
      }
      .comment {
        Line("Demonstrate protocol usage")
      }

      // Demonstrate protocol composition
      Function("demonstrateElectricVehicle") {
        Parameter(name: "vehicle", type: "Vehicle & Electric", isUnnamed: true)
      } _: {
        Call("demonstrateVehicle") {
          ParameterExp(name: "", value: "vehicle")
        }
        Call("print") {
          ParameterExp(name: "", value: "\"Battery level: \\(vehicle.batteryLevel)%\"")
        }
        VariableExp("vehicle").call("charge")
      }
      .comment {
        Line("Demonstrate protocol composition")
      }

      // Test the implementations
      Call("print") {
        ParameterExp(name: "", value: "\"Testing regular car:\"")
      }
      .comment {
        Line("Test the implementations")
      }
      Call("demonstrateVehicle") {
        ParameterExp(name: "", value: "toyota")
      }

      Call("print") {
        ParameterExp(name: "", value: "\"Testing electric car:\"")
      }
      Call("demonstrateElectricVehicle") {
        ParameterExp(name: "", value: "tesla")
      }
    }
  }

  // MARK: - Tests

  @Test("Complete protocols example with Call generates correct syntax")
  internal func testCompleteProtocolsExample() throws {
    let generatedCode = createProtocolsDSL().generateCode()

    // Verify protocol definitions
    #expect(generatedCode.contains("protocol Vehicle"))
    #expect(generatedCode.contains("var numberOfWheels"))
    #expect(generatedCode.contains("var brand"))
    #expect(generatedCode.contains("func start()"))
    #expect(generatedCode.contains("func stop()"))

    // Verify protocol extension
    #expect(generatedCode.contains("extension Vehicle"))
    #expect(generatedCode.contains("print(\"Starting \\(brand) vehicle...\")"))
    #expect(generatedCode.contains("print(\"Stopping \\(brand) vehicle...\")"))

    // Verify protocol composition
    #expect(generatedCode.contains("protocol Electric"))
    #expect(generatedCode.contains("var batteryLevel"))
    #expect(generatedCode.contains("func charge()"))

    // Verify concrete types
    #expect(generatedCode.contains("struct Car:Vehicle"))
    #expect(generatedCode.contains("struct ElectricCar:Vehicle"))
    #expect(generatedCode.contains("print(\"Starting \\(brand) car engine...\")"))
    #expect(generatedCode.contains("print(\"Charging \\(brand) electric car...\")"))

    // Verify usage examples
    #expect(generatedCode.contains("let tesla"))
    #expect(generatedCode.contains("let toyota"))

    // Verify demonstration functions
    #expect(generatedCode.contains("func demonstrateVehicle"))
    #expect(generatedCode.contains("func demonstrateElectricVehicle"))
    #expect(generatedCode.contains("print(\"Vehicle brand: \\(vehicle.brand)\")"))
    #expect(generatedCode.contains("print(\"Number of wheels: \\(vehicle.numberOfWheels)\")"))
    #expect(generatedCode.contains("print(\"Battery level: \\(vehicle.batteryLevel)%\")"))

    // Verify test calls
    #expect(generatedCode.contains("print(\"Testing regular car:\")"))
    #expect(generatedCode.contains("print(\"Testing electric car:\")"))
  }

  @Test("Protocols DSL and code.swift generate equivalent code")
  internal func testProtocolsDSLAndCodeSwiftEquivalence() throws {
    // Hardcoded code.swift content
    let codeSwift = """
      // MARK: - Protocol Definition
      protocol Vehicle {
        var numberOfWheels: Int { get }
        var brand: String { get }
        func start()
        func stop()
      }

      // MARK: - Protocol Extension
      extension Vehicle {
        func start() {
          print("Starting \\(brand) vehicle...")
        }

        func stop() {
          print("Stopping \\(brand) vehicle...")
        }
      }

      // MARK: - Protocol Composition
      protocol Electric {
        var batteryLevel: Double { get set }
        func charge()
      }

      // MARK: - Concrete Types
      struct Car: Vehicle {
        let numberOfWheels: Int = 4
        let brand: String

        func start() {
          print("Starting \\(brand) car engine...")
        }
      }

      struct ElectricCar: Vehicle, Electric {
        let numberOfWheels: Int = 4
        let brand: String
        var batteryLevel: Double

        func charge() {
          print("Charging \\(brand) electric car...")
          batteryLevel = 100.0
        }
      }

      // MARK: - Usage Example
      let tesla = ElectricCar(brand: "Tesla", batteryLevel: 75.0)
      let toyota = Car(brand: "Toyota")

      // Demonstrate protocol usage
      func demonstrateVehicle(_ vehicle: Vehicle) {
        print("Vehicle brand: \\(vehicle.brand)")
        print("Number of wheels: \\(vehicle.numberOfWheels)")
        vehicle.start()
        vehicle.stop()
      }

      // Demonstrate protocol composition
      func demonstrateElectricVehicle(_ vehicle: Vehicle & Electric) {
        demonstrateVehicle(vehicle)
        print("Battery level: \\(vehicle.batteryLevel)%")
        vehicle.charge()
      }

      // Test the implementations
      print("Testing regular car:")
      demonstrateVehicle(toyota)

      print("Testing electric car:")
      demonstrateElectricVehicle(tesla)
      """

    // Evaluate the DSL directly
    let generatedCode = createProtocolsDSL().generateCode()

    // Normalize both
    let normalizedCode = codeSwift.normalize()
    let normalizedGenerated = generatedCode.normalize()
    #expect(normalizedCode == normalizedGenerated)
  }
}
