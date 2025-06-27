protocol Stackable {
    associatedtype Element : Hashable & Identifiable

    mutating func push(_ item: Element)
    mutating func pop() -> Element?
    func peek() -> Element?
    var isEmpty: Bool { get }
    var count: Int { get }
}
struct Stack<Element> {
    private var items: [Element] = []

    mutating func push(_ item: Element) {
        items.append(item)
    }

    mutating func pop() -> Element? {
        items.popLast()
    }

    func peek() -> Element? {
        items.last
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    var count: Int {
        items.count
    }
}

enum Noop {
    static func nothing(_ stack: any Stackable) -> any Stackable { 
        return stack
    }
}
