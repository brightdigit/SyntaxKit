import SwiftSyntax

/// A Swift ternary conditional operator expression (`condition ? then : else`).
public struct ConditionalOp: CodeBlock {
    private let condition: CodeBlock
    private let thenExpression: CodeBlock
    private let elseExpression: CodeBlock
    
    /// Creates a ternary conditional operator expression.
    /// - Parameters:
    ///   - if: The condition expression.
    ///   - then: The expression to evaluate if the condition is true.
    ///   - else: The expression to evaluate if the condition is false.
    public init(
        if condition: CodeBlock,
        then thenExpression: CodeBlock,
        else elseExpression: CodeBlock
    ) {
        self.condition = condition
        self.thenExpression = thenExpression
        self.elseExpression = elseExpression
    }
    
    public var syntax: SyntaxProtocol {
        let conditionExpr = ExprSyntax(
            fromProtocol: condition.syntax.as(ExprSyntax.self)
                ?? DeclReferenceExprSyntax(baseName: .identifier(""))
        )
        
        // Handle EnumCase specially - use asExpressionSyntax for expressions
        let thenExpr: ExprSyntax
        if let enumCase = thenExpression as? EnumCase {
            thenExpr = enumCase.asExpressionSyntax
        } else {
            thenExpr = ExprSyntax(
                fromProtocol: thenExpression.syntax.as(ExprSyntax.self)
                    ?? DeclReferenceExprSyntax(baseName: .identifier(""))
            )
        }
        
        let elseExpr: ExprSyntax
        if let enumCase = elseExpression as? EnumCase {
            elseExpr = enumCase.asExpressionSyntax
        } else {
            elseExpr = ExprSyntax(
                fromProtocol: elseExpression.syntax.as(ExprSyntax.self)
                    ?? DeclReferenceExprSyntax(baseName: .identifier(""))
            )
        }
        
        return TernaryExprSyntax(
            condition: conditionExpr,
            questionMark: .infixQuestionMarkToken(leadingTrivia: .space, trailingTrivia: .space),
            thenExpression: thenExpr,
            colon: .colonToken(leadingTrivia: .space, trailingTrivia: .space),
            elseExpression: elseExpr
        )
    }
} 