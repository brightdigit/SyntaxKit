@objc
class Foo {
    @Published var bar: String = "bar"

    @available(iOS 17.0, *)
    func bar() {
        print("bar")
    }

    @MainActor
    func baz() {
        print("baz")
    }    
}