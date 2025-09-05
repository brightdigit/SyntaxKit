//
//  File.swift
//  SyntaxKit
//
//  Created by Leo Dion on 9/5/25.
//

internal typealias CodeBlockExtractor = @Sendable (String) throws(CodeBlockExtractorError) ->
  [CodeBlock]
