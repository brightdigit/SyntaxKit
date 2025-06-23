import SwiftSyntax

/// A Swift weak reference expression (e.g., `weak self`).
public struct WeakReferenceExp: CodeBlock {
    private let base: CodeBlock
    private let referenceType: String
    
    /// Creates a weak reference expression.
    /// - Parameters:
    ///   - base: The base expression to reference.
    ///   - referenceType: The type of reference (e.g., "weak", "unowned").
    public init(base: CodeBlock, referenceType: String) {
        self.base = base
        self.referenceType = referenceType
    }
    
    public var syntax: SyntaxProtocol {
        // For capture lists, we need to create a proper weak reference
        // This will be handled by the Closure syntax when used in capture lists
        let baseExpr = ExprSyntax(
            fromProtocol: base.syntax.as(ExprSyntax.self)
                ?? DeclReferenceExprSyntax(baseName: .identifier(""))
        )
        
        // Create a custom expression that represents a weak reference
        // This will be used by the Closure to create proper capture syntax
        return baseExpr
    }
    
    /// Returns the reference type for use in capture lists
    var captureSpecifier: String {
        referenceType
    }
    
    /// Returns the base expression for use in capture lists
    var captureExpression: CodeBlock {
        base
    }
} 