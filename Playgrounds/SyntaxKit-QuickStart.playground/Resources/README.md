# SyntaxKit Quick Start Playground

Welcome to the interactive SyntaxKit Quick Start Playground! This playground provides hands-on experience with SyntaxKit's dynamic Swift code generation capabilities.

## What's Inside

This playground demonstrates:

- **Dynamic Enum Generation**: Transform JSON configuration into Swift enums
- **Multiple Examples**: HTTP status codes, priority levels, log levels
- **Interactive Learning**: Modify configurations and see immediate results
- **Real-World Applications**: Practical use cases for code generation

## How to Use

1. **Open in Xcode**: Double-click the `.playground` file to open in Xcode
2. **Run the Code**: Press ⌘+Shift+Return to execute the playground
3. **Explore**: Modify JSON configurations and see the generated Swift code
4. **Experiment**: Create your own enum configurations

## Key Features Demonstrated

### JSON → Swift Code
```json
{
  "name": "HTTPStatus",
  "cases": [
    {"name": "ok", "value": "200"},
    {"name": "notFound", "value": "404"}
  ]
}
```

Becomes:
```swift
enum HTTPStatus: Int, CaseIterable {
    case ok = 200
    case notFound = 404
}
```

### Real SyntaxKit Usage

In a real project with SyntaxKit installed, the code generation would look like:

```swift
import SyntaxKit

let enumDecl = Enum("HTTPStatus", conformsTo: ["Int", "CaseIterable"]) {
    Case("ok", rawValue: "200")
    Case("notFound", rawValue: "404")
}

let swiftCode = enumDecl.formatted().description
```

## Next Steps

After exploring this playground:

1. **Install SyntaxKit**: Add to your project via Swift Package Manager
2. **Read the Tutorials**: Explore macro development and advanced examples
3. **Build Real Tools**: Create CLI tools and code generators
4. **Join the Community**: Contribute to SyntaxKit development

## Links

- [SyntaxKit GitHub Repository](https://github.com/brightdigit/SyntaxKit)
- [Full Documentation](https://swiftpackageindex.com/brightdigit/SyntaxKit/documentation)
- [Package on Swift Package Index](https://swiftpackageindex.com/brightdigit/SyntaxKit)

---

**Generated with SyntaxKit** - Dynamic Swift Code Generation Made Simple