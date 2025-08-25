import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SKSampleMacroMacros)
import SKSampleMacroMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
]
#endif

@Suite
struct SKSampleMacroTests {
    @Test
    func macro() throws {
        #if canImport(SKSampleMacroMacros)
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw Test.Skip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test
    func macroWithStringLiteral() throws {
        #if canImport(SKSampleMacroMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw Test.Skip("macros are only supported when running tests for the host platform")
        #endif
    }
}
