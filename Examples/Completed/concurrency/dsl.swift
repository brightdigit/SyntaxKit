Enum("VendingMachineError") {
    Case("invalidSelection")
    Case("insufficientFunds").associatedValue("coinsNeeded", type: "Int")
    Case("outOfStock")
}

Class("VendingMachine") {
    Variable(.var, name: "inventory", equals: Literal.dictionary(Dictionary(uniqueKeysWithValues: [
        ("Candy Bar", Item(price: 12, count: 7)),
        ("Chips", Item(price: 10, count: 4)),
        ("Pretzels", Item(price: 7, count: 11))
    ])))
    Variable(.var, name: "coinsDeposited", equals: 0)

    Function("vend"){
        Parameter("name", labeled: "itemNamed", type: "String")
    } _: {
        Guard("let item = inventory[itemNamed]") else: {
            Throw(
                EnumValue("VendingMachineError", case: "invalidSelection")
            )
        }
        Guard("item.count > 0") else: {
            Throw(
                EnumValue("VendingMachineError", case: "outOfStock")
            )
        }
        Guard("item.price <= coinsDeposited") else: {
            Throw(
                EnumValue("VendingMachineError", case: "insufficientFunds"){
                    ParameterExp("coinsNeeded", value: Infix("-"){
                        VariableExp("item").property("price")
                        VariableExp("coinsDeposited")
                    })
                }
            )
        }
        Infix("-=", "coinsDeposited", VariableExp("item").property("price"))
        Variable("newItem", equals: VariableExp("item"))
        Infix("-=", "newItem.count", 1)
        Assignment("inventory[itemNamed]", .ref("newItem"))
        Call("print", "Dispensing \\(itemNamed)")
    }
}




