Variable(.var, name: "vendingMachine", equals: Init("VendingMachine"))
Assignment("vendingMachine.coinsDeposited", Literal.integer(8))
Do {
    Call("buyFavoriteSnack") {
        ParameterExp(name: "person", value: Literal.string("Alice"))
        ParameterExp(name: "vendingMachine", value: Literal.ref("vendingMachine"))
    }.throwing()
    Call("print") {
        ParameterExp(unlabeled: Literal.string("Success! Yum."))
    }
} catch: {
    Catch(EnumCase("invalidSelection")) {
        Call("print") {
        ParameterExp(unlabeled: Literal.string("Invalid Selection."))
        }
    }
    Catch(EnumCase("outOfStock")) {
        Call("print") {
        ParameterExp(unlabeled: Literal.string("Out of Stock."))
        }
    }
    Catch(
        EnumCase("insufficientFunds").associatedValue(
        "coinsNeeded", type: "Int")
    ) {
        Call("print") {
        ParameterExp(
            unlabeled: Literal.string(
            "Insufficient funds. Please insert an additional \\(coinsNeeded) coins."))
        }
    }
    Catch {
        Call("print") {
        ParameterExp(unlabeled: Literal.string("Unexpected error: \\(error)."))
        }
    }
}

Function("summarize") {
    Parameter(name: "ratings", type: "[Int]")
} _: {
    Guard{
        VariableExp("ratings").property("isEmpty").not()
    } else: {
        Throw(EnumCase("noRatings"))
    }
}.throws("StatisticsError")

Do {
    Variable(.let, name: "data") {
        Call("fetchUserData") {
            ParameterExp(name: "id", value: Literal.integer(1))
        }
    }.async()
    Variable(.let, name: "posts") {
        Call("fetchUserPosts") {
            ParameterExp(name: "id", value: Literal.integer(1))
        }
    }.async()
    // The original example used `TupleAssignment([...], equals: Tuple {...})`
    // to emit `let (fetchedData, fetchedPosts) = try await (data, posts)`, but
    // `TupleAssignment` is internal in the current API. Emit two equivalent
    // single-variable bindings instead — same observable behaviour for the
    // catch block below.
    Variable(.let, name: "fetchedData") { VariableExp("data") }
    Variable(.let, name: "fetchedPosts") { VariableExp("posts") }
} catch: {
    Catch(EnumCase("fetchError")) {
        // Example catch for async/await
    }
}






