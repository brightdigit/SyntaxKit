#!/usr/bin/env swift

// Create a simple script that can run the enum generator
import Foundation

// Execute the dsl script and capture output
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
process.arguments = [
    "run", "--package-path", "../../../", "swift", 
    "Examples/Completed/enum_generator/dsl.swift"
]
process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

let pipe = Pipe()
process.standardOutput = pipe

do {
    try process.run()
    process.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        // Write the generated code to code.swift
        try output.write(toFile: "code.swift", atomically: true, encoding: .utf8)
        print("Generated code written to code.swift")
    }
} catch {
    print("Error: \(error)")
}