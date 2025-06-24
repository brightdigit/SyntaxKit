import SyntaxKit

// MARK: - For Loops Examples
Group {
    // MARK: - Basic For-in Loop
    Variable(.let, name: "names", equals: Literal.array([Literal.string("Alice"), Literal.string("Bob"), Literal.string("Charlie")]))
      .comment {
        Line("MARK: - Basic For-in Loop")
        Line("Simple for-in loop over an array")
      }
    
    For(VariableExp("name"), in: VariableExp("names"), then: {
        Call("print") {
            ParameterExp(unlabeled: "\"Hello, \\(name)!\"")
        }
    })

    // MARK: - For-in with Enumerated
    Call("print") {
        ParameterExp(unlabeled: "\"\\n=== For-in with Enumerated ===\"")
    }
      .comment {
        Line("MARK: - For-in with Enumerated")
        Line("For-in loop with enumerated() to get index and value")
      }
    For(Tuple.patternCodeBlock([VariableExp("index"), VariableExp("name")]), in: VariableExp("names").call("enumerated"), then: {
        Call("print") {
            ParameterExp(unlabeled: "\"Index: \\(index), Name: \\(name)\"")
        }
    })

    // MARK: - For-in with Where Clause
    Call("print") {
        ParameterExp(unlabeled: "\"\\n=== For-in with Where Clause ===\"")
    }
      .comment {
        Line("MARK: - For-in with Where Clause")
        Line("For-in loop with where clause")
      }
    Variable(.let, name: "numbers", equals: Literal.array([Literal.integer(1), Literal.integer(2), Literal.integer(3), Literal.integer(4), Literal.integer(5), Literal.integer(6), Literal.integer(7), Literal.integer(8), Literal.integer(9), Literal.integer(10)]))
    
    For(VariableExp("number"), in: VariableExp("numbers"), where: {
        try Infix("==") {
            try Infix("%") {
                VariableExp("number")
                Literal.integer(2)
            }
            Literal.integer(0)
        }
    }, then: {
        Call("print") {
            ParameterExp(unlabeled: "\"Even number: \\(number)\"")
        }
    })

    // MARK: - For-in with Dictionary
    Call("print") {
        ParameterExp(unlabeled: "\"\\n=== For-in with Dictionary ===\"")
    }
      .comment {
        Line("MARK: - For-in with Dictionary")
        Line("For-in loop over dictionary")
      }
    Variable(.let, name: "scores", equals: Literal.dictionary([(Literal.string("Alice"), Literal.integer(95)), (Literal.string("Bob"), Literal.integer(87)), (Literal.string("Charlie"), Literal.integer(92))]))
    
    For(Tuple.patternCodeBlock([VariableExp("name"), VariableExp("score")]), in: VariableExp("scores"), then: {
        Call("print") {
            ParameterExp(unlabeled: "\"\\(name): \\(score)\"")
        }
    })
} 
