import SyntaxKit

// Generate and print the code
let generatedCode = Group {
    // MARK: - Protocol Definition
    Protocol("Vehicle") {
        PropertyRequirement("numberOfWheels", type: "Int", access: .get)
        PropertyRequirement("brand", type: "String", access: .get)
        FunctionRequirement("start")
        FunctionRequirement("stop")
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
    
    // MARK: - Protocol Composition
    Protocol("Electric") {
        PropertyRequirement("batteryLevel", type: "Double", access: .getSet)
        FunctionRequirement("charge")
    }
    
    // MARK: - Concrete Types
    Struct("Car") {
        Variable(.let, name: "numberOfWheels", type: "Int", equals: "4")
        Variable(.let, name: "brand", type: "String")
        
        Function("start") {
            Call("print") {
                ParameterExp(name: "", value: "\"Starting \\(brand) car engine...\"")
            }
        }
    }.inherits("Vehicle")
    
    Struct("ElectricCar") {
        Variable(.let, name: "numberOfWheels", type: "Int", equals: "4")
        Variable(.let, name: "brand", type: "String")
        Variable(.var, name: "batteryLevel", type: "Double")
        
        Function("charge") {
            Call("print") {
                ParameterExp(name: "", value: "\"Charging \\(brand) electric car...\"")
            }
            Assignment("batteryLevel", Literal.float(100.0))
        }
    }.inherits("Vehicle")
    
    // MARK: - Usage Example
    VariableDecl(.let, name: "tesla", equals: "ElectricCar(brand: \"Tesla\", batteryLevel: 75.0)")
    VariableDecl(.let, name: "toyota", equals: "Car(brand: \"Toyota\")")
    
    // Demonstrate protocol usage
    Function("demonstrateVehicle") {
        Parameter(name: "vehicle", type: "Vehicle")
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
    
    // Demonstrate protocol composition
    Function("demonstrateElectricVehicle") {
        Parameter(name: "vehicle", type: "Vehicle & Electric")
    } _: {
        VariableExp("demonstrateVehicle").call("demonstrateVehicle") {
            ParameterExp(name: "vehicle", value: "vehicle")
        }
        Call("print") {
            ParameterExp(name: "", value: "\"Battery level: \\(vehicle.batteryLevel)%\"")
        }
        VariableExp("vehicle").call("charge")
    }
    
    // Test the implementations
    Call("print") {
        ParameterExp(name: "", value: "\"Testing regular car:\"")
    }
    VariableExp("demonstrateVehicle").call("demonstrateVehicle") {
        ParameterExp(name: "vehicle", value: "toyota")
    }
    
    Call("print") {
        ParameterExp(name: "", value: "\"Testing electric car:\"")
    }
    VariableExp("demonstrateElectricVehicle").call("demonstrateElectricVehicle") {
        ParameterExp(name: "vehicle", value: "tesla")
    }
}

print(generatedCode.generateCode()) 