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
    print("The string \"\(possibleNumber)\" has an integer value of \(actualNumber)")
} else {
    print("The string \"\(possibleNumber)\" could not be converted to an integer")
}

// Multiple optional bindings
let possibleName: String? = "John"
let possibleAge: Int? = 30
if let name = possibleName, let age = possibleAge {
    print("\(name) is \(age) years old")
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
    
    print("Hello \(name), you are \(ageInt) years old")
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
print("There are \(naturalCount) \(countedThings).")

// Switch with tuple matching
let somePoint = (1, 1)
switch somePoint {
case (0, 0):
    print("(0, 0) is at the origin")
case (_, 0):
    print("(\(somePoint.0), 0) is on the x-axis")
case (0, _):
    print("(0, \(somePoint.1)) is on the y-axis")
case (-2...2, -2...2):
    print("(\(somePoint.0), \(somePoint.1)) is inside the box")
default:
    print("(\(somePoint.0), \(somePoint.1)) is outside of the box")
}

// Switch with value binding
let anotherPoint = (2, 0)
switch anotherPoint {
case (let x, 0):
    print("on the x-axis with an x value of \(x)")
case (0, let y):
    print("on the y-axis with a y value of \(y)")
case let (x, y):
    print("somewhere else at (\(x), \(y))")
}

// MARK: - Fallthrough
// Using fallthrough in switch
let integerToDescribe = 5
var description = "The number \(integerToDescribe) is"
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
board[03] = 8
board[06] = 11
board[09] = 9
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

// MARK: - For Loops
// For-in loop with enumerated() to get index and value
print("\n=== For-in with Enumerated ===")
for (index, name) in names.enumerated() {
    print("\(index): \(name)")
}

// For-in loop with where clause
print("\n=== For-in with Where Clause ===")
let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
for number in numbers where number % 2 == 0 {
    print("Even number: \(number)")
}


