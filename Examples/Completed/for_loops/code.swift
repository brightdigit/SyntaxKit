// MARK: - Basic For-in Loop
// Simple for-in loop over an array
let names = ["Alice", "Bob", "Charlie"]
for name in names {
    print("Hello, \(name)!")
}

// MARK: - For-in with Enumerated
// For-in loop with enumerated() to get index and value
print("\n=== For-in with Enumerated ===")
for (index, name) in names.enumerated() {
    print("Index: \(index), Name: \(name)")
}

// MARK: - For-in with Where Clause
// For-in loop with where clause
print("\n=== For-in with Where Clause ===")
let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
for number in numbers where number % 2 == 0 {
    print("Even number: \(number)")
}

// MARK: - For-in with Dictionary
// For-in loop over dictionary
print("\n=== For-in with Dictionary ===")
let scores = ["Alice": 95, "Bob": 87, "Charlie": 92]
for (name, score) in scores {
    print("\(name): \(score)")
}
