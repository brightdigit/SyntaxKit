import Foundation
import SwiftParser
import SwiftSyntax
import Testing

/// Harness for extracting and testing documentation code examples
internal class DocumentationTestHarness {
  /// Swift code validator instance
  private let codeValidator = SwiftCodeValidator()

  /// Default file extensions for documentation files
  private static let defaultPathExtensions = ["md"]
  /// Validates all code examples in all documentation files
  internal func validateAllExamples() async throws -> [ValidationResult] {
    let documentationFiles = try DocumentationTestHarness.findDocumentationFiles()
    var allResults: [ValidationResult] = []

    for filePath in documentationFiles {
      let results = try await validateExamplesInFile(filePath)
      allResults.append(contentsOf: results)
    }

    return allResults
  }

  /// Validates code examples in a specific file
  internal func validateExamplesInFile(_ fileURL: URL) async throws -> [ValidationResult] {
    // let fullPath = try resolveFilePath(filePath)
    let content = try String(contentsOf: fileURL)

    let codeBlocks = try CodeBlockExtractor()(content)
    var results: [ValidationResult] = []

    for (index, codeBlock) in codeBlocks.enumerated() {
      let parameters = CodeBlockValidationParameters(
        code: codeBlock.code,
        fileURL: fileURL,
        lineNumber: codeBlock.lineNumber,
        blockIndex: index,
        blockType: codeBlock.blockType
      )
      let result = await validateCodeBlock(parameters)

      try results.append(
        #require(result)
      )
    }

    return results
  }

  /// Validates a single code block
  private func validateCodeBlock(
    _ parameters: CodeBlockValidationParameters
  ) -> ValidationResult? {
    switch parameters.blockType {
    case .example:
      // Test compilation and basic execution
      return validateSwiftExample(parameters)

    case .packageManifest:
      #if canImport(Foundation) && (os(macOS) || os(Linux))
        // Package.swift files need special handling
        var processError: ProcessError?
        do {
          try validatePackageManifest(parameters.code)
          processError = nil
        } catch {
          processError = error
        }
        return ValidationResult(
          parameters: parameters, testType: .parsing,
          error: processError.map { ValidationError.processError($0) })
      #else
        return ValidationResult(
          parameters: parameters,
          testType: .skipped,
          error: nil
        )
      #endif
    case .shellCommand:
      // Skip shell commands for now
      return ValidationResult(
        parameters: parameters,
        testType: .skipped,
        error: nil
      )
    }
  }

  //  /// Convenience method for backward compatibility
  //  private func validateCodeBlock(
  //
  //  ) async -> ValidationResult? {
  //    let parameters = CodeBlockValidationParameters(
  //      code: code,
  //      fileURL: fileURL,
  //      blockIndex: blockIndex,
  //      lineNumber: lineNumber,
  //      blockType: blockType
  //    )
  //    return await validateCodeBlock(parameters)
  //  }

  /// Validates a Swift code example
  private func validateSwiftExample(
    _ parameters: CodeBlockValidationParameters
  ) -> ValidationResult {
    codeValidator.validateSwiftExample(
      parameters
    )
  }

  #if canImport(Foundation) && (os(macOS) || os(Linux))
    /// Validates a Package.swift manifest
    private func validatePackageManifest(
      _ code: String
    ) throws(ProcessError) {
      let process = Process()
      do {
        // Create temporary Package.swift and validate it parses
        let tempDir = FileManager.default.temporaryDirectory
          .appendingPathComponent("SyntaxKit-DocTest-\(UUID())")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let packageFile = tempDir.appendingPathComponent("Package.swift")
        try code.write(to: packageFile, atomically: true, encoding: .utf8)

        // Use swift package tools to validate
        process.currentDirectoryURL = tempDir
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["package", "describe", "--type", "json"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()
      } catch {
        throw .setupError(error)
      }

      guard process.terminationStatus == 0 else {
        return
      }

      throw .packageValidationFailed
    }
  #endif

  /// Finds all documentation files containing code examples
  @available(*, deprecated, message: "Use findDocumentationFiles(in:pathExtensions:) instead")
  private static func findDocumentationFiles() throws -> [URL] {
    try Settings.docPaths.flatMap { docPath in
      let absolutePath = Settings.projectRoot.appendingPathComponent(docPath)
      return try FileManager.default.findDocumentationFiles(
        in: absolutePath, pathExtensions: Self.defaultPathExtensions)
    }
  }
}
