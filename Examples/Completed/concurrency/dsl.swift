Enum("VendingMachineError") {
    EnumCase("invalidSelection")
    EnumCase("insufficientFunds").associatedValue("coinsNeeded", type: "Int")
    EnumCase("outOfStock")
}
.inherits("Error")

Class("VendingMachine") {
    // Dictionary values are `Init`-expressions of an external `Item` type, which
    // Literal.dictionary's typed cases can't represent — emit the literal as raw
    // Swift source via VariableExp.
    Variable(.var, name: "inventory") {
        VariableExp("""
            [
                "Candy Bar": Item(price: 12, count: 7),
                "Chips": Item(price: 10, count: 4),
                "Pretzels": Item(price: 7, count: 11)
            ]
            """)
    }
    Variable(.var, name: "coinsDeposited", equals: 0)

    Function("vend") {
        Parameter("name", labeled: "itemNamed", type: "String")
    } _: {
        Guard {
            Let("item", "inventory[itemNamed]")
        } else: {
            Throw(VariableExp("VendingMachineError.invalidSelection"))
        }
        Guard {
            Infix(">", lhs: VariableExp("item.count"), rhs: Literal.integer(0))
        } else: {
            Throw(VariableExp("VendingMachineError.outOfStock"))
        }
        Guard {
            Infix("<=", lhs: VariableExp("item.price"), rhs: VariableExp("coinsDeposited"))
        } else: {
            Throw(VariableExp(
                "VendingMachineError.insufficientFunds(coinsNeeded: item.price - coinsDeposited)"
            ))
        }
        Infix("-=", lhs: VariableExp("coinsDeposited"), rhs: VariableExp("item.price"))
        Variable(.var, name: "newItem") { VariableExp("item") }
        Infix("-=", lhs: VariableExp("newItem.count"), rhs: Literal.integer(1))
        Assignment("inventory[itemNamed]", VariableExp("newItem"))
        Call("print") {
            ParameterExp(unlabeled: Literal.string("Dispensing \\(itemNamed)"))
        }
    }.throws()
}
