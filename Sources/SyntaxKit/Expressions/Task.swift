import SwiftSyntax

/// A Swift Task expression for structured concurrency.
public struct Task: CodeBlock {
    private let body: [CodeBlock]
    private var attributes: [AttributeInfo] = []
    
    /// Creates a Task expression.
    /// - Parameter content: A ``CodeBlockBuilder`` that provides the body of the task.
    public init(@CodeBlockBuilderResult _ content: () -> [CodeBlock]) {
        self.body = content()
    }
    
    /// Adds an attribute to the task.
    /// - Parameters:
    ///   - attribute: The attribute name (without the @ symbol).
    ///   - arguments: The arguments for the attribute, if any.
    /// - Returns: A copy of the task with the attribute added.
    public func attribute(_ attribute: String, arguments: [String] = []) -> Self {
        var copy = self
        copy.attributes.append(AttributeInfo(name: attribute, arguments: arguments))
        return copy
    }
    
    public var syntax: SyntaxProtocol {
        let bodyBlock = CodeBlockSyntax(
            leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
            statements: CodeBlockItemListSyntax(
                body.compactMap { block in
                    var item: CodeBlockItemSyntax?
                    if let decl = block.syntax.as(DeclSyntax.self) {
                        item = CodeBlockItemSyntax(item: .decl(decl))
                    } else if let expr = block.syntax.as(ExprSyntax.self) {
                        item = CodeBlockItemSyntax(item: .expr(expr))
                    } else if let stmt = block.syntax.as(StmtSyntax.self) {
                        item = CodeBlockItemSyntax(item: .stmt(stmt))
                    }
                    return item?.with(\.trailingTrivia, .newline)
                }
            ),
            rightBrace: .rightBraceToken(leadingTrivia: .newline)
        )
        
        let taskExpr = FunctionCallExprSyntax(
            calledExpression: ExprSyntax(
                DeclReferenceExprSyntax(baseName: .identifier("Task"))
            ),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax([
                LabeledExprSyntax(
                    label: nil,
                    colon: nil,
                    expression: ExprSyntax(
                        ClosureExprSyntax(
                            signature: nil,
                            statements: bodyBlock.statements
                        )
                    )
                )
            ]),
            rightParen: .rightParenToken()
        )
        
        // Add attributes if present
        if !attributes.isEmpty {
            // For now, just return the task expression without attributes
            // since AttributedExprSyntax is not available
            return ExprSyntax(taskExpr)
        } else {
            return ExprSyntax(taskExpr)
        }
    }
    
    private func buildAttributeList(from attributes: [AttributeInfo]) -> AttributeListSyntax {
        if attributes.isEmpty {
            return AttributeListSyntax([])
        }
        let attributeElements = attributes.map { attributeInfo in
            let arguments = attributeInfo.arguments
            
            var leftParen: TokenSyntax?
            var rightParen: TokenSyntax?
            var argumentsSyntax: AttributeSyntax.Arguments?
            
            if !arguments.isEmpty {
                leftParen = .leftParenToken()
                rightParen = .rightParenToken()
                
                let argumentList = arguments.map { argument in
                    DeclReferenceExprSyntax(baseName: .identifier(argument))
                }
                
                argumentsSyntax = .argumentList(
                    LabeledExprListSyntax(
                        argumentList.enumerated().map { index, expr in
                            var element = LabeledExprSyntax(expression: ExprSyntax(expr))
                            if index < argumentList.count - 1 {
                                element = element.with(\.trailingComma, .commaToken(trailingTrivia: .space))
                            }
                            return element
                        }
                    )
                )
            }
            
            return AttributeListSyntax.Element(
                AttributeSyntax(
                    atSign: .atSignToken(),
                    attributeName: IdentifierTypeSyntax(name: .identifier(attributeInfo.name)),
                    leftParen: leftParen,
                    arguments: argumentsSyntax,
                    rightParen: rightParen
                )
            )
        }
        return AttributeListSyntax(attributeElements)
    }
} 