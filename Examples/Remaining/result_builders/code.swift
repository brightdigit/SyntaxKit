
var vendingMachine = VendingMachine()
vendingMachine.coinsDeposited = 8
do {
    try buyFavoriteSnack(person: "Alice", vendingMachine: vendingMachine)
    print("Success! Yum.")
} catch VendingMachineError.invalidSelection {
    print("Invalid Selection.")
} catch VendingMachineError.outOfStock {
    print("Out of Stock.")
} catch VendingMachineError.insufficientFunds(let coinsNeeded) {
    print("Insufficient funds. Please insert an additional \(coinsNeeded) coins.")
} catch {
    print("Unexpected error: \(error).")
}

func summarize(_ ratings: [Int]) throws(StatisticsError) {
    guard !ratings.isEmpty else { throw .noRatings }
}

// MARK: - Task Groups
func fetchMultipleUsers(ids: [Int]) async throws -> [String] {
    try await withThrowingTaskGroup(of: String.self) { group in
        for id in ids {
            group.addTask {
                try await fetchUserData(id: id)
            }
        }

        var results: [String] = []
        for try await result in group {
            results.append(result)
        }
        return results
    }
}

// Demonstrate concurrent tasks
print("\nFetching user data and posts concurrently...")
async let data = fetchUserData(id: 1)
async let posts = fetchUserPosts(id: 1)
let (fetchedData, fetchedPosts) = try await (data, posts)
print("Data: \(fetchedData)")
print("Posts: \(fetchedPosts)")


Task {
    _ = try await fetchUserData(id: 1)
}

Task { @MainActor [unowned self] in
    _ = try await fetchUserData(id: 1)
}


func nonThrowingFunction() throws(Never) {
    
}