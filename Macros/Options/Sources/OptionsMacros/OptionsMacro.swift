//
//  OptionsMacro.swift
//  SimulatorServices
//
//  Created by Leo Dion.
//  Copyright © 2024 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import SwiftSyntax
import SwiftSyntaxMacros

#if canImport(SyntaxKit)
import SyntaxKit
public struct OptionsMacro: ExtensionMacro, PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw InvalidDeclError.kind(declaration.kind)
    }

    // Extract the type name
    let typeName = enumDecl.name

    // Extract all EnumCaseElementSyntax from the enum
    let caseElements: [EnumCaseElementSyntax] = enumDecl.memberBlock.members.flatMap { (member) -> [EnumCaseElementSyntax] in
      guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
        return [EnumCaseElementSyntax]()
      }
      return Array(caseDecl.elements)
    }

    // Build mappedValues variable declaration (static let mappedValues = [...])
    // Check if any case has a raw value to determine if we need a dictionary
    let hasRawValues = caseElements.contains { $0.rawValue != nil }
    
    let mappedValuesVariable: Variable
    if hasRawValues {
      let keyValues: [Int: String] = caseElements.reduce(into: [:]) { (result, element) in
        guard let rawValue = element.rawValue?.value.as(IntegerLiteralExprSyntax.self)?.literal.text,
              let key = Int(rawValue) else {
          return
        }
        result[key] = element.name.trimmed.text
      }
      mappedValuesVariable = Variable(.let, name: "mappedValues", equals: keyValues).static()
    } else {
      let caseNames: [String] = caseElements.map { element in
        element.name.trimmed.text
      }
      mappedValuesVariable = Variable(.let, name: "mappedValues", equals: caseNames).static()
    }
    
    let extensionDecl = Extension(typeName.trimmed.text) {
      TypeAlias("MappedType", equals: "String")
      mappedValuesVariable
    }.inherits("MappedValueRepresentable", "MappedValueRepresented")

    return [extensionDecl.syntax.as(ExtensionDeclSyntax.self)!]
    
  }
  
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw InvalidDeclError.kind(declaration.kind)
    }
    
    let typeName = enumDecl.name
    let aliasName = "\(typeName.trimmed)Set"
    let aliasDecl = TypeAlias(aliasName, equals: "EnumSet<\(typeName)>").syntax
    
    guard let declSyntax : DeclSyntax = DeclSyntax(aliasDecl.as(TypeAliasDeclSyntax.self)) else {
      throw InvalidDeclError.kind(declaration.kind)
    }
    return [
      declSyntax
    ]
  }
  
}
#else
public struct OptionsMacro: ExtensionMacro, PeerMacro {
  public static func expansion(
    of _: SwiftSyntax.AttributeSyntax,
    providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in _: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw InvalidDeclError.kind(declaration.kind)
    }
    let typeName = enumDecl.name
    
    let aliasName: TokenSyntax = "\(typeName.trimmed)Set"
    
    let initializerName: TokenSyntax = "EnumSet<\(typeName)>"
    
    return [
      .init(TypeAliasDeclSyntax(name: aliasName, for: initializerName))
    ]
  }
  
  public static func expansion(
    of _: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf _: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo protocols: [SwiftSyntax.TypeSyntax],
    in _: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw InvalidDeclError.kind(declaration.kind)
    }
    
    let extensionDecl = try ExtensionDeclSyntax(
      enumDecl: enumDecl, conformingTo: protocols
    )
    return [extensionDecl]
  }
}
#endif
