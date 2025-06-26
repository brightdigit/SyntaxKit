//
//  Skit.swift
//  SyntaxKit
//
//  Created by Leo Dion on 6/26/25.
//

import ArgumentParser
import Foundation
import SyntaxKit

@main
struct Skit:ParsableCommand {
  static let configuration: CommandConfiguration = .init(
    subcommands: [
      Parse.self,
      Generate.self
    ],
    defaultSubcommand: Generate.self
  )
}

struct Parse: ParsableCommand {
  func run() throws {
    // Read Swift code from stdin
    let code =
      String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""

    do {
      // Parse the code using SyntaxKit
      let response = try SyntaxParser.parse(code: code, options: ["fold"])

      // Output the JSON to stdout
      print(response.syntaxJSON)
    } catch {
      // If there's an error, output it as JSON
      let errorResponse = ["error": error.localizedDescription]
      if let jsonData = try? JSONSerialization.data(withJSONObject: errorResponse),
        let jsonString = String(data: jsonData, encoding: .utf8)
      {
        print(jsonString)
      }
    }

  }
}


struct Generate: ParsableCommand {
  func run() throws {
    let dsl =
      String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
    
    let code = try SyntaxKitGenerator.generateCode(from: dsl)
    
    print(code)
    
  }
}
