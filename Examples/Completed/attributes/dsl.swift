Class("Foo") {
    Variable(.var, name: "bar", type: "String", defaultValue: "bar").attribute("Published")
    Function("bar") {
        print("bar")
    }.attribute("available", arguments: ["iOS 17.0", "*"])
    Function("baz") {
}.attribute("objc")}.attribute("objc")