//
//  CodeBlockValidationParameters.swift
//  SyntaxKit
//
//  Created by Leo Dion on 9/5/25.
//

import Foundation

/// Parameters for validating code blocks with additional metadata
internal struct CodeBlockValidationParameters: ValidationParameters, Sendable {
  internal let code: String
  internal let fileURL: URL
  internal let lineNumber: Int
  internal let blockIndex: Int
  internal let blockType: CodeBlockType
}
