import SyntaxKit

// Example of generating a BlackjackCard struct with a nested Suit enum
Struct("BlackjackCard") {
    Enum("Suit") {
        EnumCase("spades").equals("♠")
        EnumCase("hearts").equals("♡")
        EnumCase("diamonds").equals("♢")
        EnumCase("clubs").equals("♣")
    }
    .inherits("Character")

    Enum("Rank") {
        EnumCase("two").equals(2)
        EnumCase("three")
        EnumCase("four")
        EnumCase("five")
        EnumCase("six")
        EnumCase("seven")
        EnumCase("eight")
        EnumCase("nine")
        EnumCase("ten")
        EnumCase("jack")
        EnumCase("queen")
        EnumCase("king")
        EnumCase("ace")
        Struct("Values") {
            Variable(.let, name: "first", type: "Int")
            Variable(.let, name: "second", type: "Int?")
        }
        ComputedProperty("values", type: "Values") {
            Switch("self") {
                SwitchCase(".ace") {
                    Return {
                        Init("Values") {
                            ParameterExp(name: "first", value: "1")
                            ParameterExp(name: "second", value: "11")
                        }
                    }
                }
                SwitchCase(".jack", ".queen", ".king") {
                    Return {
                        Init("Values") {
                            ParameterExp(name: "first", value: "10")
                            ParameterExp(name: "second", value: "nil")
                        }
                    }
                }
                Default {
                    Return {
                        Init("Values") {
                            ParameterExp(name: "first", value: "self.rawValue")
                            ParameterExp(name: "second", value: "nil")
                        }
                    }
                }
            }
        }
    }
    .inherits("Int")

    Variable(.let, name: "rank", type: "Rank")
    Variable(.let, name: "suit", type: "Suit")

    ComputedProperty("description", type: "String") {
        Variable(.var, name: "output", equals: "suit is \\(suit.rawValue),")
        PlusAssign("output", " value is \\(rank.values.first)")
        If(Let("second", "rank.values.second"), then: {
            PlusAssign("output", " or \\(second)")
        })
        Return {
            VariableExp("output")
        }
    }
}
