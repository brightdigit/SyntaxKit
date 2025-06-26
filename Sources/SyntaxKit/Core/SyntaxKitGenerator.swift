//
//  SyntaxKitGenerator.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

/// A generator that can compile and execute SyntaxKit DSL code from a string
/// and return the generated Swift code.
public struct SyntaxKitGenerator {
  
  /// Generates Swift code from a string containing SyntaxKit DSL code.
  /// 
  /// This method takes a string of SyntaxKit DSL code, compiles it using the Swift compiler,
  /// executes it, and returns the generated Swift code.
  /// 
  /// - Parameters:
  ///   - dslCode: A string containing valid SyntaxKit DSL code
  ///   - outputVariable: The name of the variable that contains the generated code (default: "result")
  /// - Returns: The generated Swift code as a string
  /// - Throws: `SyntaxKitGeneratorError` if compilation or execution fails
  public static func generateCode(from dslCode: String, outputVariable: String = "result") throws -> String {
    let tempDir = FileManager.default.temporaryDirectory
    let uniqueID = UUID().uuidString
    let workDir = tempDir.appendingPathComponent("SyntaxKit-\(uniqueID)")
    
    // Create working directory
    try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
    defer {
      // Clean up working directory
      try? FileManager.default.removeItem(at: workDir)
    }
    
    // Create the Sources directory structure
    let sourcesDir = workDir.appendingPathComponent("Sources")
    let targetDir = sourcesDir.appendingPathComponent("SyntaxKitGenerator")
    try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
    
    // Create the main Swift file with the DSL code
    let mainSwiftFile = targetDir.appendingPathComponent("main.swift")
    let swiftCode = createSwiftCode(dslCode: dslCode, outputVariable: outputVariable)
    try swiftCode.write(to: mainSwiftFile, atomically: true, encoding: .utf8)
    
    // Create Package.swift for dependencies
    let packageFile = workDir.appendingPathComponent("Package.swift")
    let packageContent = createPackageSwift()
    try packageContent.write(to: packageFile, atomically: true, encoding: .utf8)
    
    // Compile and run the code
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
    process.arguments = ["run"]
    process.currentDirectoryURL = workDir
    
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe
    
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus != 0 {
      let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
      let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
      throw SyntaxKitGeneratorError.compilationFailed(errorOutput)
    }
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: outputData, encoding: .utf8) ?? ""
    
    return output.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  private static func createSwiftCode(dslCode: String, outputVariable: String) -> String {
    return """
    import Foundation
    import SyntaxKit
    
    // DSL Code to execute
    \(dslCode)
    
    // Print the generated code
    print(\(outputVariable).generateCode())
    """
  }
  
  private static func createPackageSwift() -> String {
    // Get the current project directory by looking for the Package.swift file
    let currentDirectory = getCurrentProjectDirectory()
    
    return """
    // swift-tools-version: 5.9
    import PackageDescription
    
    let package = Package(
        name: "SyntaxKitGenerator",
        platforms: [.macOS(.v13)],
        dependencies: [
            .package(path: "\(currentDirectory)")
        ],
        targets: [
            .executableTarget(
                name: "SyntaxKitGenerator",
                dependencies: ["SyntaxKit"]
            )
        ]
    )
    """
  }
  
  private static func getCurrentProjectDirectory() -> String {
    // Try multiple approaches to find the project directory
    
    // Approach 1: Look for the Bundle's bundlePath (if running from a built app)
    let bundlePath = Bundle.main.bundlePath
    let bundleDir = (bundlePath as NSString).deletingLastPathComponent
    if FileManager.default.fileExists(atPath: (bundleDir as NSString).appendingPathComponent("Package.swift")) {
      return bundleDir
    }
    
    // Approach 2: Use the current working directory and walk up
    var currentPath = FileManager.default.currentDirectoryPath
    
    // Walk up the directory tree to find the project root
    while !currentPath.isEmpty && currentPath != "/" {
      let packagePath = (currentPath as NSString).appendingPathComponent("Package.swift")
      if FileManager.default.fileExists(atPath: packagePath) {
        return currentPath
      }
      currentPath = (currentPath as NSString).deletingLastPathComponent
    }
    
    // Approach 3: Try to find the project by looking for Sources/SyntaxKit
    let possiblePaths = [
      "/Users/leo/Documents/Projects/SyntaxKit", // Hardcoded fallback
      FileManager.default.currentDirectoryPath,
      ProcessInfo.processInfo.environment["PWD"] ?? ""
    ]
    
    for path in possiblePaths {
      let sourcesPath = (path as NSString).appendingPathComponent("Sources/SyntaxKit")
      if FileManager.default.fileExists(atPath: sourcesPath) {
        return path
      }
    }
    
    // Fallback: return current directory and let the compiler error out
    return FileManager.default.currentDirectoryPath
  }
}

/// Errors that can occur during code generation
public enum SyntaxKitGeneratorError: Error, LocalizedError {
  case compilationFailed(String)
  case executionFailed(String)
  
  public var errorDescription: String? {
    switch self {
    case .compilationFailed(let error):
      return "Compilation failed: \(error)"
    case .executionFailed(let error):
      return "Execution failed: \(error)"
    }
  }
} 