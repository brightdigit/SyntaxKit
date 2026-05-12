Class("Foo") {
    Variable(.var, name: "bar", type: "String", equals: "bar").attribute("Published")
    Function("bar") {
        Call("print") {
            ParameterExp(unlabeled: Literal.string("bar"))
        }
    }.attribute("available", arguments: ["iOS 17.0", "*"])
    Function("baz") {
    }.attribute("objc")
}
