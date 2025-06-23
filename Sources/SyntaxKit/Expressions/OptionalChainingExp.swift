import SwiftSyntax

/// A Swift optional chaining expression (e.g., `self?`).
public struct OptionalChainingExp: CodeBlock {
    private let base: CodeBlock
    
    /// Creates an optional chaining expression.
    /// - Parameter base: The base expression to make optional.
    public init(base: CodeBlock) {
        self.base = base
    }
    
    public var syntax: SyntaxProtocol {
        // Convert base.syntax to ExprSyntax more safely
        let baseExpr: ExprSyntax
        if let exprSyntax = base.syntax.as(ExprSyntax.self) {
            baseExpr = exprSyntax
        } else {
            // Fallback to a default expression if conversion fails
            baseExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("")))
        }
        
        // Add optional chaining operator
        return PostfixOperatorExprSyntax(
            expression: baseExpr,
            operator: .postfixOperator("?", trailingTrivia: [])
        )
    }
} 