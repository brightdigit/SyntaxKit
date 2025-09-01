# When to Use SyntaxKit

A practical guide to deciding when SyntaxKit will make your Swift development easier and when it might just add unnecessary complexity.

## What You'll Learn

By the end of this tutorial, you'll be able to quickly decide whether SyntaxKit is the right tool for your specific use case. We'll cover real scenarios you'll encounter and give you concrete decision-making frameworks.

## The Simple Rule of Thumb

Here's the quick way to decide: **Are you generating Swift code programmatically, or writing it once by hand?**

- **Writing once by hand?** → Use regular Swift
- **Generating programmatically?** → Consider SyntaxKit

## Common Scenarios: When to Use SyntaxKit

### ✅ Great Use Cases

#### 1. Building Swift Macros
If you're creating Swift macros, SyntaxKit is almost always the right choice. Macros need to generate Swift code, and SyntaxKit makes this much cleaner than raw SwiftSyntax.

**Example**: Creating a `@Codable` macro
```swift
// Without SyntaxKit: 150+ lines of complex AST manipulation
// With SyntaxKit: Clean, readable code generation
let members = Group {
    Enum("CodingKeys", conformsTo: ["String", "CodingKey"]) {
        for property in properties {
            Case(property.name)
        }
    }
    
    Function("init") {
        Parameter("from decoder", type: "Decoder")
    }
    .throws()
    .body {
        // Much cleaner than manual AST construction
    }
}
```



#### 2. Database Schema to Swift Models
If you're generating Swift models from database schemas, SyntaxKit will save you tons of boilerplate.

**Example**: PostgreSQL schema to Swift models
```swift
let models = generateModels(from: databaseSchema) {
    for table in schema.tables {
        Struct(table.name.swiftCase) {
            // Primary key
            Property(table.primaryKey.name, type: table.primaryKey.swiftType)
                .immutable()
            
            // Regular columns
            for column in table.columns.filter({ !$0.isPrimaryKey }) {
                Property(column.name, type: column.swiftType)
                    .optional(column.nullable)
            }
        }
    }
}
```

#### 3. Developer Tools and Code Generators
Building tools that generate boilerplate code for your team? SyntaxKit makes this much more maintainable.

**Example**: Generating view controllers from design specs
```swift
func generateViewController(name: String, properties: [Property]) -> ClassDecl {
    Class("\(name)ViewController") {
        // IBOutlet properties
        for property in properties {
            Property(property.name, type: "\(property.type)!")
                .attribute("IBOutlet")
                .weak()
        }
        
        // Lifecycle methods
        Function("viewDidLoad")
            .override()
            .body {
                Call("super.viewDidLoad")
                Call("setupUI")
            }
    }
    .inherits("UIViewController")
}
```

### ❌ When NOT to Use SyntaxKit

#### 1. Regular Application Code
Don't use SyntaxKit for your app's business logic, view controllers, or standard Swift code.

```swift
// ❌ Don't do this
let loginViewController = Class("LoginViewController") {
    Function("viewDidLoad") {
        Call("super.viewDidLoad")
    }
}

// ✅ Just write normal Swift
class LoginViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
```

#### 2. Simple One-Time Scripts
For basic utilities or simple transformations, regular Swift is often clearer.

```swift
// ❌ Overkill
let converter = Function("convertToUppercase") {
    Parameter("input", type: "String")
}
.returns("String")
.body {
    Return { VariableExp("input.uppercased()") }
}

// ✅ Much simpler
func convertToUppercase(_ input: String) -> String {
    return input.uppercased()
}
```

#### 3. Static Configuration
If your code structure is fixed and won't change, just write it directly.

```swift
// ❌ Unnecessary complexity
let config = Struct("Config") {
    Variable(.let, name: "apiURL", equals: "\"https://api.example.com\"")
}

// ✅ Direct and clear
struct Config {
    let apiURL = "https://api.example.com"
}
```

## Decision Framework

Ask yourself these questions:

1. **Will this code be generated multiple times?** (Yes → SyntaxKit)
2. **Does the structure depend on external data?** (Yes → SyntaxKit)  
3. **Are you building a tool that generates code?** (Yes → SyntaxKit)
4. **Is this one-time application logic?** (Yes → Regular Swift)
5. **Is this simple enough to write by hand?** (Yes → Regular Swift)

**Rule of thumb**: If you answered "yes" to questions 1-3, SyntaxKit is probably right. If you answered "yes" to questions 4-5, stick with regular Swift.

## Real-World Examples

### Scenario 1: You're Building a Swift Macro
**Use SyntaxKit** - Macros need to generate Swift code, and SyntaxKit makes this much cleaner than raw SwiftSyntax.

### Scenario 2: You're Converting JSON Schema to Swift Models
**Use SyntaxKit** - You'll be generating lots of similar code structures from external data.

### Scenario 3: You're Building a CLI Tool That Generates Swift Code
**Use SyntaxKit** - Perfect for tools that create boilerplate or scaffold code.

### Scenario 4: You're Writing a Standard iOS App
**Use Regular Swift** - No code generation needed, just write your app logic directly.

### Scenario 5: You're Creating a Simple Utility Function
**Use Regular Swift** - Unless it's part of a larger code generation system.

## Performance Considerations

- **Compilation time**: SyntaxKit adds a small overhead during compilation
- **Runtime performance**: Generated code runs exactly the same as hand-written code
- **Development speed**: SyntaxKit can significantly speed up development for code generation tasks

**Bottom line**: The compilation overhead is usually worth it for code generation tasks, but not for simple application code.

## Common Mistakes to Avoid

### Mistake 1: Using SyntaxKit for Everything
```swift
// ❌ Don't over-engineer simple cases
let simpleProperty = Property("name", type: "String")

// ✅ Just write it
let name: String
```

### Mistake 2: Generating App Logic
```swift
// ❌ Don't generate view controllers
let viewController = Class("HomeViewController") {
    Function("viewDidLoad") { /* app logic */ }
}

// ✅ Write standard iOS code
class HomeViewController: UIViewController {
    override func viewDidLoad() { /* app logic */ }
}
```

### Mistake 3: Premature Optimization
```swift
// ❌ Don't start with SyntaxKit "just in case"
let futureProofStruct = generateStruct(from: hardcodedData)

// ✅ Start simple, migrate when needed
struct SimpleModel {
    let data: String
}
```

## Quick Reference

```swift
// ✅ Good SyntaxKit use: Dynamic generation
let models = generateModels(from: databaseSchema) {
    for table in schema.tables {
        Struct(table.name) {
            for column in table.columns {
                Property(column.name, type: column.swiftType)
            }
        }
    }
}

// ❌ Poor SyntaxKit use: Static application code
class AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
```

## Summary

**Use SyntaxKit when you're transforming external data into Swift code structures.** It's perfect for macros, API clients, model generators, and developer tools.

**Use regular Swift for application logic, one-time scripts, and static code structures.**

The key is to match the tool to the task. SyntaxKit is powerful for code generation, but it's not a replacement for writing Swift code directly when that's what you need.

## Next Steps

Ready to get started? Check out:

- <doc:Creating-Macros-with-SyntaxKit> - Build your first macro
- [Quick Start Guide](https://swiftpackageindex.com/brightdigit/SyntaxKit/documentation) - 5-minute hands-on experience
- [Best Practices Article](https://swiftpackageindex.com/brightdigit/SyntaxKit/documentation) - Advanced patterns and optimization

## See Also

- ``Struct``
- ``Enum``
- ``Function``
- ``Class``
- ``Extension``
