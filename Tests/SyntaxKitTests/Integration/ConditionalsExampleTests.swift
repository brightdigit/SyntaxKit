import Foundation
import Testing

@testable import SyntaxKit

@Suite internal struct ConditionalsExampleTests {
  @Test("Completed conditionals DSL generates expected Swift code")
  internal func testCompletedConditionalsExample() throws {
    // Build DSL equivalent of Examples/Completed/conditionals/dsl.swift

    let program = try Group {
      // MARK: Basic If Statements
      Variable(.let, name: "temperature", equals: 25)
        .comment {
          Line("Simple if statement")
        }

      try If {
        try Infix(">") {
          VariableExp("temperature")
          Literal.integer(30)
        }
      } then: {
        Call("print") {
          ParameterExp(unlabeled: "\"It's hot outside!\"")
        }
      }

      // If-else chain with else-if
      Variable(.let, name: "score", equals: 85)
        .comment {
          Line("If-else statement")
        }

      try If {
        try Infix(">=") {
          VariableExp("score")
          Literal.integer(90)
        }
      } then: {
        Call("print") {
          ParameterExp(unlabeled: "\"Excellent!\"")
        }
      } else: {
        try If {
          try Infix(">=") {
            VariableExp("score")
            Literal.integer(80)
          }
        } then: {
          Call("print") {
            ParameterExp(unlabeled: "\"Good job!\"")
          }
        } else: {
          try If {
            try Infix(">=") {
              VariableExp("score")
              Literal.integer(70)
            }
          } then: {
            Call("print") {
              ParameterExp(unlabeled: "\"Passing\"")
            }
          } else: {
            Call("print") {
              ParameterExp(unlabeled: "\"Needs improvement\"")
            }
          }
        }
      }

      // MARK: Optional Binding with If
      Variable(.let, name: "possibleNumber", equals: Literal.string("123"))
        .comment {
          Line("MARK: - Optional Binding with If")
          Line("Using if let for optional binding")
        }

      If(
        Let("actualNumber", "Int(possibleNumber)"),
        then: {
          Call("print") {
            ParameterExp(
              name: "",
              value:
                "\"The string \"\\(possibleNumber)\" has an integer value of \\(actualNumber)\""
            )
          }
        },
        else: {
          Call("print") {
            ParameterExp(
              name: "",
              value: "\"The string \"\\(possibleNumber)\" could not be converted to an integer\""
            )
          }
        }
      )

      // Multiple optional bindings
      Variable(.let, name: "possibleName", type: "String?", equals: Literal.string("John"))
        .withExplicitType()
        .comment {
          Line("Multiple optional bindings")
        }
      Variable(.let, name: "possibleAge", type: "Int?", equals: Literal.integer(30))
        .withExplicitType()

      If {
        Let("name", "possibleName")
        Let("age", "possibleAge")
      } then: {
        Call("print") {
          ParameterExp(name: "", value: "\"\\(name) is \\(age) years old\"")
        }
      }

      // MARK: - Guard Statements
      try Function(
        "greet",
        {
          Parameter(name: "person", type: "[String: String]")
        },
        {
          Guard {
            Let("name", "person[\"name\"]")
          } else: {
            Call("print") {
              ParameterExp(name: "", value: "\"No name provided\"")
            }
          }

          Guard {
            Let("age", "person[\"age\"]")
            Let("ageInt", "Int(age)")
          } else: {
            Call("print") {
              ParameterExp(name: "", value: "\"Invalid age provided\"")
            }
          }

          Call("print") {
            ParameterExp(name: "", value: "\"Hello \\(name), you are \\(ageInt) years old\"")
          }
        }
      )
      .comment {
        Line("MARK: - Guard Statements")
      }

      // MARK: - Switch Statements
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
        SwitchCase(100..<1_000) {
          Assignment("naturalCount", Literal.string("hundreds of"))
        }
        Default {
          Assignment("naturalCount", Literal.string("many"))
        }
      }
      Call("print") {
        ParameterExp(name: "", value: "\"There are \\(naturalCount) \\(countedThings).\"")
      }

      // MARK: - Tuple literal and tuple pattern switch
      Variable(.let, name: "somePoint", equals: Literal.tuple([.integer(1), .integer(1)]))
        .comment {
          Line("Switch with tuple matching")
        }
      Switch("somePoint") {
        SwitchCase(Tuple.pattern([0, 0])) {
          Call("print") {
            ParameterExp(name: "", value: "\"(0, 0) is at the origin\"")
          }
        }
        SwitchCase(Tuple.pattern([nil, 0])) {
          Call("print") {
            ParameterExp(name: "", value: "\"(\\(somePoint.0), 0) is on the x-axis\"")
          }
        }
        SwitchCase(Tuple.pattern([0, nil])) {
          Call("print") {
            ParameterExp(name: "", value: "\"(0, \\(somePoint.1)) is on the y-axis\"")
          }
        }
        SwitchCase(Tuple.pattern([(-2...2), (-2...2)])) {
          Call("print") {
            ParameterExp(
              name: "", value: "\"(\\(somePoint.0), \\(somePoint.1)) is inside the box\""
            )
          }
        }
        Default {
          Call("print") {
            ParameterExp(
              name: "", value: "\"(\\(somePoint.0), \\(somePoint.1)) is outside of the box\""
            )
          }
        }
      }

      // MARK: - Switch with value binding
      Variable(.let, name: "anotherPoint", equals: Literal.tuple([.integer(2), .integer(0)]))
        .withExplicitType()
        .comment {
          Line("Switch with value binding")
        }
      Switch("anotherPoint") {
        SwitchCase(Tuple.pattern([Pattern.let("x"), 0])) {
          Call("print") {
            ParameterExp(
              name: "", value: "\"on the x-axis with an x value of \\(x)\""
            )
          }
        }
        SwitchCase(Tuple.pattern([0, Pattern.let("y")])) {
          Call("print") {
            ParameterExp(
              name: "", value: "\"on the y-axis with a y value of \\(y)\""
            )
          }
        }
        SwitchCase(Tuple.pattern([Pattern.let("x"), Pattern.let("y")])) {
          Call("print") {
            ParameterExp(
              name: "", value: "\"somewhere else at (\\(x), \\(y))\""
            )
          }
        }
      }

      // MARK: - Fallthrough
      Variable(.let, name: "integerToDescribe", equals: Literal.integer(5))
        .comment {
          Line("MARK: - Fallthrough")
          Line("Using fallthrough in switch")
        }
      Variable(.var, name: "description", equals: "The number \\(integerToDescribe) is")
      Switch("integerToDescribe") {
        SwitchCase(2, 3, 5, 7, 11, 13, 17, 19) {
          PlusAssign("description", " a prime number, and also")
          Fallthrough()
        }
        Default {
          PlusAssign("description", " an integer.")
        }
      }
      Call("print") {
        ParameterExp(name: "", value: "description")
      }

      // MARK: - Labeled Statements
      Variable(.let, name: "finalSquare", equals: Literal.integer(25))
        .comment {
          Line("MARK: - Labeled Statements")
          Line("Using labeled statements with break")
        }
      try Variable(.var, name: "board") {
        try Init("[Int]") {
          ParameterExp(name: "repeating", value: Literal.integer(0))
          ParameterExp(
            name: "count",
            value: try Infix("+") {
              VariableExp("finalSquare")
              Literal.integer(1)
            }
          )
        }
      }

      // Board setup
      Assignment("board[3]", 8)
      Assignment("board[6]", 11)
      Assignment("board[9]", 9)
      Assignment("board[10]", 2)
      Assignment("board[14]", -10)
      Assignment("board[19]", -11)
      Assignment("board[22]", -2)
      Assignment("board[24]", -8)

      Variable(.var, name: "square", equals: Literal.integer(0))
      Variable(.var, name: "diceRoll", equals: Literal.integer(0))
      try While(
        try Infix("!=") {
          VariableExp("square")
          VariableExp("finalSquare")
        }
      ) {
        PlusAssign("diceRoll", 1)
        try If {
          try Infix("==") {
            VariableExp("diceRoll")
            Literal.integer(7)
          }
        } then: {
          Assignment("diceRoll", 1)
        }
        try Switch(
          try Infix("+") {
            VariableExp("square")
            VariableExp("diceRoll")
          }
        ) {
          SwitchCase("finalSquare") {
            Break()
          }
          try SwitchCase {
            SwitchLet("newSquare")
            try Infix(">") {
              VariableExp("newSquare")
              VariableExp("finalSquare")
            }
          } content: {
            Continue()
          }
          try Default {
            try Infix("+=") {
              VariableExp("square")
              VariableExp("diceRoll")
            }
            try Infix("+=") {
              VariableExp("square")
              VariableExp("board[square]")
            }
          }
        }
      }
    }

    // Generate Swift from DSL
    var generated = program.generateCode()

    // Remove type annotations like ": Int =" for comparison to example code
    generated = generated.normalize()

    // Use the expected Swift code as a string literal
    let expected = """
      // Simple if statement
      let temperature = 25
      if temperature > 30 {
        print("It's hot outside!")
      }

      // If-else statement
      let score = 85
      if score >= 90 {
        print("Excellent!")
      } else if score >= 80 {
        print("Good job!")
      } else if score >= 70 {
        print("Passing")
      } else {
        print("Needs improvement")
      }

      // MARK: - Optional Binding with If

      // Using if let for optional binding
      let possibleNumber = "123"
      if let actualNumber = Int(possibleNumber) {
        print("The string \"\\(possibleNumber)\" has an integer value of \\(actualNumber)")
      } else {
        print("The string \"\\(possibleNumber)\" could not be converted to an integer")
      }

      // Multiple optional bindings
      let possibleName: String? = "John"
      let possibleAge: Int? = 30
      if let name = possibleName, let age = possibleAge {
        print("\\(name) is \\(age) years old")
      }

      // MARK: - Guard Statements
      func greet(person: [String: String]) {
        guard let name = person["name"] else {
          print("No name provided")
          return
        }

        guard let age = person["age"], let ageInt = Int(age) else {
          print("Invalid age provided")
          return
        }

        print("Hello \\(name), you are \\(ageInt) years old")
      }

      // MARK: - Switch Statements
      // Switch with range matching
      let approximateCount = 62
      let countedThings = "moons orbiting Saturn"
      let naturalCount: String
      switch approximateCount {
      case 0:
        naturalCount = "no"
      case 1..<5:
        naturalCount = "a few"
      case 5..<12:
        naturalCount = "several"
      case 12..<100:
        naturalCount = "dozens of"
      case 100..<1000:
        naturalCount = "hundreds of"
      default:
        naturalCount = "many"
      }
      print("There are \\(naturalCount) \\(countedThings).")

      // Switch with tuple matching
      let somePoint = (1, 1)
      switch somePoint {
      case (0, 0):
        print("(0, 0) is at the origin")
      case (_, 0):
        print("(\\(somePoint.0), 0) is on the x-axis")
      case (0, _):
        print("(0, \\(somePoint.1)) is on the y-axis")
      case (-2...2, -2...2):
        print("(\\(somePoint.0), \\(somePoint.1)) is inside the box")
      default:
        print("(\\(somePoint.0), \\(somePoint.1)) is outside of the box")
      }

      // Switch with value binding
      let anotherPoint: (Int, Int) = (2, 0)
      switch anotherPoint {
      case (let x, 0):
        print("on the x-axis with an x value of \\(x)")
      case (0, let y):
        print("on the y-axis with a y value of \\(y)")
      case (let x, let y):
        print("somewhere else at (\\(x), \\(y))")
      }

      // MARK: - Fallthrough
      // Using fallthrough in switch
      let integerToDescribe = 5
      var description = "The number \\(integerToDescribe) is"
      switch integerToDescribe {
      case 2, 3, 5, 7, 11, 13, 17, 19:
        description += " a prime number, and also"
        fallthrough
      default:
        description += " an integer."
      }
      print(description)

      // MARK: - Labeled Statements
      // Using labeled statements with break
      let finalSquare = 25
      var board = [Int](repeating: 0, count: finalSquare + 1)
      board[3] = 8
      board[6] = 11
      board[9] = 9
      board[10] = 2
      board[14] = -10
      board[19] = -11
      board[22] = -2
      board[24] = -8

      var square = 0
      var diceRoll = 0
      while square != finalSquare {
        diceRoll += 1
        if diceRoll == 7 { diceRoll = 1 }
        switch square + diceRoll {
        case finalSquare:
          break
        case let newSquare where newSquare > finalSquare:
          continue
        default:
          square += diceRoll
          square += board[square]
        }
      }
      """
      .normalize()

    #expect(generated == expected)
  }

  @Test("Conditionals example generates correct syntax")
  internal func testConditionalsExample() throws {
    _ = try If {
      try Infix(">") {
        VariableExp("temperature")
        Literal.integer(30)
      }
    } then: {
      Call("print") {
        ParameterExp(unlabeled: "It's hot!")
      }
    } else: {
      try If {
        try Infix(">=") {
          VariableExp("score")
          Literal.integer(90)
        }
      } then: {
        Call("print") {
          ParameterExp(unlabeled: "Excellent!")
        }
      } else: {
        try If {
          try Infix(">=") {
            VariableExp("score")
            Literal.integer(80)
          }
        } then: {
          Call("print") {
            ParameterExp(unlabeled: "Good!")
          }
        } else: {
          try If {
            try Infix(">=") {
              VariableExp("score")
              Literal.integer(70)
            }
          } then: {
            Call("print") {
              ParameterExp(unlabeled: "Pass")
            }
          } else: {
            Call("print") {
              ParameterExp(unlabeled: "Fail")
            }
          }
        }
      }
    }
    // ... rest of the test ...
  }
}
