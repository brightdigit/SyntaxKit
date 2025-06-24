Group {
    Variable(.let, name: "temperature", equals: Literal.integer(25))
      .comment {
        Line("Simple if statement")
      }
    If {
        Infix("temperature", ">", 30)
    } then: {
        Call("print", "It's hot outside!")
    }
    Variable(.let, name: "score", equals: Literal.integer(85))
      .comment {
        Line("If-else statement")
      }
    If {
        Infix("score", ">=", 90)
    } then: {
        Call("print", "Excellent!")
    } else: {
        If {
            Infix("score", ">=", 80)
        } then: {
            Call("print", "Good job!")
        }
        If {
            try! Infix("score", ">=", 70)
        } then: {
            Call("print", "Passing")
        }
        Then {
            Call("print", "Needs improvement")
        }
    }

    Variable(.let, name: "possibleNumber", equals: Literal.string("123"))
      .comment {
        Line("MARK: - Optional Binding with If")
        Line("Using if let for optional binding")
      }
    If(Let("actualNumber", Init("Int") {
        ParameterExp(name: "", value: "possibleNumber")
    }), then: {
        Call("print", "The string \"\\(possibleNumber)\" has an integer value of \\(actualNumber)")
    }, else: {
        Call("print", "The string \"\\(possibleNumber)\" could not be converted to an integer")
    })

    Variable(.let, name: "possibleName", type: "String?", equals: Literal.string("John")).withExplicitType()
      .comment {
        Line("Multiple optional bindings")
      }
    Variable(.let, name: "possibleAge", type: "Int?", equals: Literal.integer(30)).withExplicitType()
    If {
        Let("name", "possibleName")
        Let("age", "possibleAge")
    } then: {
        Call("print", "\\(name) is \\(age) years old") 
    }

    Function("greet", parameters: [Parameter("person", type: "[String: String]")]) {
        Guard {
            Let("name", "person[\"name\"]")
        } else: {
            Call("print", "No name provided")
        }
        Guard {
            Let("age", "person[\"age\"]")
            Let("ageInt", Init("Int") {
                ParameterExp(name: "", value: "age")
            })
        } else: {
            Call("print", "Invalid age provided")
        }
        Call("print", "Hello \\(name), you are \\(ageInt) years old")
    }
}.comment {
    Line("MARK: - Guard Statements")
}

Variable(.let, name: "approximateCount", equals: Literal.integer(62))
  .comment {
    Line("MARK: - Switch Statements")
    Line("Switch with range matching")
  }
Variable(.let, name: "countedThings", equals: Literal.string("moons orbiting Saturn"))
Variable(.let, name: "naturalCount", type: "String").withExplicitType()
Switch("approximateCount") {
    SwitchCase(0) {
        Assignment("naturalCount", Literal.string("no"))
    }
    SwitchCase(1..<5) {
        Assignment("naturalCount", Literal.string("a few"))
    }
    SwitchCase(5..<12) {
        Assignment("naturalCount", Literal.string("several"))
    }
    SwitchCase(12..<100) {
        Assignment("naturalCount", Literal.string("dozens of"))
    }
    SwitchCase(100..<1000) {
        Assignment("naturalCount", Literal.string("hundreds of"))
    }
    Default {
        Assignment("naturalCount", Literal.string("many"))
    }
}
Call("print", "There are \\(naturalCount) \\(countedThings).")
Variable(.let, name: "somePoint", type: "(Int, Int)", equals: VariableExp("(1, 1)"), explicitType: true)
.comment {
    Line("Switch with tuple matching")
}
Switch("somePoint") {
    SwitchCase(Tuple.pattern([0, 0])) {
        Call("print", "(0, 0) is at the origin")
    }
    SwitchCase(Tuple.pattern([nil, 0])) {
        Call("print", "(\(somePoint.0), 0) is on the x-axis")
    }
    SwitchCase(Tuple.pattern([0, nil])) {
        Call("print", "(0, \(somePoint.1)) is on the y-axis")
    }
    SwitchCase(Tuple.pattern([(-2...2), (-2...2)])) {
        Call("print", "(\(somePoint.0), \(somePoint.1)) is inside the box")
    }
    Default {
        Call("print", "(\(somePoint.0), \(somePoint.1)) is outside of the box")
    }
}
Variable(.let, name: "anotherPoint", type: "(Int, Int)", equals: VariableExp("(2, 0)"), explicitType: true)
.comment {
    Line("Switch with value binding")
}
Switch("anotherPoint") {
    SwitchCase(Tuple.pattern([.let("x"), 0])) {
        Call("print", "on the x-axis with an x value of \(x)")
        
    }
    SwitchCase(Tuple.pattern([0, .let("y")])) {
        Call("print", "on the y-axis with a y value of \(y)")
     
    }
    SwitchCase(Tuple.pattern([.let("x"), .let("y")])) {
        Call("print", "somewhere else at (\(x), \(y))")
        
    }
}
Variable(.let, name: "integerToDescribe", equals: 5)
Variable(.var, name: "description", equals: "The number \(integerToDescribe) is")
Switch("integerToDescribe") {
    SwitchCase(2, 3, 5, 7, 11, 13, 17, 19) {
        PlusAssign("description", "a prime number, and also")
        Fallthrough()
    }
    Default {
        PlusAssign("description", "an integer.")
    }
}
Call("print", "description")

Variable(.let, name: "finalSquare", equals: 25)
Variable(.var, name: "board", equals: Literal.array(Array(repeating: Literal.integer(0), count: 26)))

Infix("board[03]", "+=", 8)
Infix("board[06]", "+=", 11)
Infix("board[09]", "+=", 9)
Infix("board[10]", "+=", 2)
Infix("board[14]", "-=", 10)
Infix("board[19]", "-=", 11)
Infix("board[22]", "-=", 2)
Infix("board[24]", "-=", 8)

Variable(.var, name: "square", equals: 0)
Variable(.var, name: "diceRoll", equals: 0)
While {
    try! Infix("square", "!=", "finalSquare")
} then: {
    Assignment("diceRoll", "+", 1)
    If {
        try! Infix("diceRoll", "==", 7)
    } then: {
        Assignment("diceRoll", 1)
    }
    Switch(try! Infix("square", "+", "diceRoll")) {
        SwitchCase("finalSquare") {
            Break()
        }
        SwitchCase(try! Infix("newSquare", ">", "finalSquare")) {
            Continue()
        }
        Default {
            try! Infix("square", "+=", "diceRoll")
            try! Infix("square", "+=", "board[square]")
        }
    }
}

Call("print", "\n=== For-in with Enumerated ===")
.comment {
    Line("MARK: - For Loops")
    Line("For-in loop with enumerated() to get index and value")
}
For {
    Tuple.pattern([VariableExp("index"), VariableExp("name")])
} in: {
    VariableExp("names").call("enumerated")
} then: {
    Call("print", "Index: \\(index), Name: \\(name)")
}

Call("print", "\n=== For-in with Where Clause ===")
.comment {
    Line("For-in loop with where clause")
}
For {
    VariableExp("numbers")
} in: {
    Literal.array([Literal.integer(1), Literal.integer(2), Literal.integer(3), Literal.integer(4), Literal.integer(5), Literal.integer(6), Literal.integer(7), Literal.integer(8), Literal.integer(9), Literal.integer(10)])
} where: {
    try! Infix("number", "%", 2)
} then: {
    Call("print", "Even number: \\(number)")
}
