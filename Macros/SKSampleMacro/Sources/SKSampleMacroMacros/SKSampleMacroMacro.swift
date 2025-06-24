import SwiftCompilerPlugin
import SwiftSyntax
//import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SyntaxKit

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
      let first = node.arguments.first?.expression
      let second = node.arguments.last?.expression
      guard let first, let second  else {
          fatalError("compiler bug: the macro does not have any arguments")
      }
      
      return Tuple{
        try! Infix("+") {
          VariableExp(first.description)
          VariableExp(second.description)
        }
        Literal.string("\(first.description) + \(second.description)")
      }.expr
    }
}

@main
struct SKSampleMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
    ]
}
