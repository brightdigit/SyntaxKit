Group {
    Variable(.let, name: "temperature", equals: Literal.integer(25))
      .comment {
        Line("Simple if statement")
      }
    If {
        Infix(">", lhs: VariableExp("temperature"), rhs: Literal.integer(30))
    } then: {
        Call("print") { ParameterExp(unlabeled: Literal.string("It's hot outside!")) }
    }
    Variable(.let, name: "score", equals: Literal.integer(85))
      .comment {
        Line("If-else statement")
      }
    If {
        Infix(">=", lhs: VariableExp("score"), rhs: Literal.integer(90))
    } then: {
        Call("print") { ParameterExp(unlabeled: Literal.string("Excellent!")) }
    } else: {
        If {
            Infix(">=", lhs: VariableExp("score"), rhs: Literal.integer(80))
        } then: {
            Call("print") { ParameterExp(unlabeled: Literal.string("Good job!")) }
        }
        If {
            Infix(">=", lhs: VariableExp("score"), rhs: Literal.integer(70))
        } then: {
            Call("print") { ParameterExp(unlabeled: Literal.string("Passing")) }
        }
        Then {
            Call("print") { ParameterExp(unlabeled: Literal.string("Needs improvement")) }
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
        Call("print") { ParameterExp(unlabeled: Literal.string("The string \"\\(possibleNumber)\" has an integer value of \\(actualNumber)")) }
    }, else: {
        Call("print") { ParameterExp(unlabeled: Literal.string("The string \"\\(possibleNumber)\" could not be converted to an integer")) }
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
        Call("print") { ParameterExp(unlabeled: Literal.string("\\(name) is \\(age) years old")) } 
    }

    Function("greet") {
        Parameter(name: "person", type: "[String: String]")
    } _: {
        Guard {
            Let("name", "person[\"name\"]")
        } else: {
            Call("print") { ParameterExp(unlabeled: Literal.string("No name provided")) }
        }
        Guard {
            Let("age", "person[\"age\"]")
            Let("ageInt", Init("Int") {
                ParameterExp(name: "", value: "age")
            })
        } else: {
            Call("print") { ParameterExp(unlabeled: Literal.string("Invalid age provided")) }
        }
        Call("print") { ParameterExp(unlabeled: Literal.string("Hello \\(name), you are \\(ageInt) years old")) }
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
Call("print") { ParameterExp(unlabeled: Literal.string("There are \\(naturalCount) \\(countedThings).")) }
Variable(.let, name: "somePoint", type: "(Int, Int)", equals: VariableExp("(1, 1)"), explicitType: true)
.comment {
    Line("Switch with tuple matching")
}
Switch("somePoint") {
    SwitchCase(Tuple.pattern([0, 0])) {
        Call("print") { ParameterExp(unlabeled: Literal.string("(0, 0) is at the origin")) }
    }
    SwitchCase(Tuple.pattern([nil, 0])) {
        Call("print") { ParameterExp(unlabeled: Literal.string("(\\(somePoint.0), 0) is on the x-axis")) }
    }
    SwitchCase(Tuple.pattern([0, nil])) {
        Call("print") { ParameterExp(unlabeled: Literal.string("(0, \\(somePoint.1)) is on the y-axis")) }
    }
    SwitchCase(Tuple.pattern([(-2...2), (-2...2)])) {
        Call("print") { ParameterExp(unlabeled: Literal.string("(\\(somePoint.0), \\(somePoint.1)) is inside the box")) }
    }
    Default {
        Call("print") { ParameterExp(unlabeled: Literal.string("(\\(somePoint.0), \\(somePoint.1)) is outside of the box")) }
    }
}
Variable(.let, name: "anotherPoint", type: "(Int, Int)", equals: VariableExp("(2, 0)"), explicitType: true)
.comment {
    Line("Switch with value binding")
}
Switch("anotherPoint") {
    SwitchCase(Tuple.pattern([Pattern.let("x"), 0])) {
        Call("print") { ParameterExp(unlabeled: Literal.string("on the x-axis with an x value of \\(x)")) }
        
    }
    SwitchCase(Tuple.pattern([0, Pattern.let("y")])) {
        Call("print") { ParameterExp(unlabeled: Literal.string("on the y-axis with a y value of \\(y)")) }
     
    }
    SwitchCase(Tuple.pattern([Pattern.let("x"), Pattern.let("y")])) {
        Call("print") { ParameterExp(unlabeled: Literal.string("somewhere else at (\\(x), \\(y))")) }
        
    }
}
Variable(.let, name: "integerToDescribe", equals: 5)
Variable(.var, name: "description", equals: "The number \\(integerToDescribe) is")
Switch("integerToDescribe") {
    SwitchCase(2, 3, 5, 7, 11, 13, 17, 19) {
        PlusAssign("description", "a prime number, and also")
        Fallthrough()
    }
    Default {
        PlusAssign("description", "an integer.")
    }
}
Call("print") { ParameterExp(unlabeled: Literal.string("description")) }

Variable(.let, name: "finalSquare", equals: 25)
Variable(.var, name: "board", equals: Literal.array(Array(repeating: Literal.integer(0), count: 26)))

Infix("+=", lhs: VariableExp("board[03]"), rhs: Literal.integer(8))
Infix("+=", lhs: VariableExp("board[06]"), rhs: Literal.integer(11))
Infix("+=", lhs: VariableExp("board[09]"), rhs: Literal.integer(9))
Infix("+=", lhs: VariableExp("board[10]"), rhs: Literal.integer(2))
Infix("-=", lhs: VariableExp("board[14]"), rhs: Literal.integer(10))
Infix("-=", lhs: VariableExp("board[19]"), rhs: Literal.integer(11))
Infix("-=", lhs: VariableExp("board[22]"), rhs: Literal.integer(2))
Infix("-=", lhs: VariableExp("board[24]"), rhs: Literal.integer(8))

Variable(.var, name: "square", equals: 0)
Variable(.var, name: "diceRoll", equals: 0)
While(Infix("!=", lhs: VariableExp("square"), rhs: VariableExp("finalSquare"))) {
    Infix("+=", lhs: VariableExp("diceRoll"), rhs: Literal.integer(1))
    If {
        Infix("==", lhs: VariableExp("diceRoll"), rhs: Literal.integer(7))
    } then: {
        Assignment("diceRoll", 1)
    }
    Switch(Infix("+", lhs: VariableExp("square"), rhs: VariableExp("diceRoll"))) {
        SwitchCase("finalSquare") {
            Break()
        }
        SwitchCase(Infix(">", lhs: VariableExp("newSquare"), rhs: VariableExp("finalSquare"))) {
            Continue()
        }
        Default {
            Infix("+=", lhs: VariableExp("square"), rhs: VariableExp("diceRoll"))
            Infix("+=", lhs: VariableExp("square"), rhs: VariableExp("board[square]"))
        }
    }
}

Call("print") { ParameterExp(unlabeled: Literal.string("\n=== For-in with Enumerated ===")) }
.comment {
    Line("MARK: - For Loops")
    Line("For-in loop with enumerated() to get index and value")
}
For(Tuple.patternCodeBlock([VariableExp("index"), VariableExp("name")]),
    in: VariableExp("names").call("enumerated"),
    then: {
        Call("print") { ParameterExp(unlabeled: Literal.string("Index: \\(index), Name: \\(name)")) }
    })

Call("print") { ParameterExp(unlabeled: Literal.string("\n=== For-in with Where Clause ===")) }
.comment {
    Line("For-in loop with where clause")
}
For(VariableExp("number"),
    in: VariableExp("numbers"),
    then: {
        If(VariableExp("number % 2 == 0"), then: {
            Call("print") { ParameterExp(unlabeled: Literal.string("Even number: \\(number)")) }
        })
    })
