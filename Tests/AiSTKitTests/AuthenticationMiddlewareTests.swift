//
//  AuthenticationMiddlewareTests.swift
//  SyntaxKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import AiSTKit

internal struct AuthenticationMiddlewareTests {
  // swiftlint:disable no_unchecked_sendable

  /// Thread-safe one-shot holder, so the `@Sendable` `next` closure can hand
  /// the request it received back to the test.
  private final class Box<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value?

    var value: Value? {
      lock.withLock { stored }
    }

    func set(_ newValue: Value) {
      lock.withLock { stored = newValue }
    }
  }
  // swiftlint:enable no_unchecked_sendable

  private static let baseURLString = "https://api.anthropic.com"

  /// Invokes the middleware with a stub `next` handler and returns the request
  /// the handler received, so tests can assert on the injected headers.
  private func interceptedRequest(
    apiKey: String,
    seedingRequest seed: (inout HTTPRequest) -> Void = { _ in }
  ) async throws -> HTTPRequest {
    let middleware = AuthenticationMiddleware(apiKey: apiKey)
    var request = HTTPRequest(
      method: .post,
      scheme: "https",
      authority: "api.anthropic.com",
      path: "/v1/messages"
    )
    seed(&request)

    let baseURL = try #require(URL(string: Self.baseURLString))
    let captured = Box<HTTPRequest>()
    _ = try await middleware.intercept(
      request,
      body: nil,
      baseURL: baseURL,
      operationID: "createMessage"
    ) { forwarded, body, url in
      captured.set(forwarded)
      #expect(body == nil)
      #expect(url == baseURL)
      return (HTTPResponse(status: .ok), nil)
    }

    return try #require(captured.value, "next handler was never invoked")
  }

  @Test internal func injectsAPIKeyHeader() async throws {
    let request = try await interceptedRequest(apiKey: "test-key-123")
    #expect(request.headerFields[try #require(.init("x-api-key"))] == "test-key-123")
  }

  @Test internal func injectsAnthropicVersionHeader() async throws {
    let request = try await interceptedRequest(apiKey: "test-key-123")
    #expect(request.headerFields[try #require(.init("anthropic-version"))] == "2023-06-01")
  }

  @Test internal func preservesExistingHeaders() async throws {
    let contentType = try #require(HTTPField.Name("content-type"))
    let request = try await interceptedRequest(apiKey: "test-key-123") { request in
      request.headerFields[contentType] = "application/json"
    }
    #expect(request.headerFields[contentType] == "application/json")
    #expect(request.headerFields[try #require(.init("x-api-key"))] == "test-key-123")
  }

  @Test internal func forwardsRequestToNextHandler() async throws {
    let request = try await interceptedRequest(apiKey: "test-key-123")
    #expect(request.method == .post)
    #expect(request.path == "/v1/messages")
  }

  @Test internal func overridesExistingAPIKeyHeader() async throws {
    let apiKeyName = try #require(HTTPField.Name("x-api-key"))
    let request = try await interceptedRequest(apiKey: "new-key") { request in
      request.headerFields[apiKeyName] = "stale-key"
    }
    #expect(request.headerFields[apiKeyName] == "new-key")
  }

  @Test internal func acceptsEmptyAPIKey() async throws {
    let request = try await interceptedRequest(apiKey: "")
    #expect(request.headerFields[try #require(.init("x-api-key"))]?.isEmpty == true)
  }
}
