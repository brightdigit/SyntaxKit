//
//  AuthenticationMiddleware.swift
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

public import HTTPTypes
public import OpenAPIRuntime

#if os(Linux)
  @preconcurrency public import struct Foundation.URL
#else
  public import struct Foundation.URL
#endif

/// OpenAPI client middleware that adds Anthropic API authentication headers.
///
/// Injects the `x-api-key` and `anthropic-version` headers into every
/// outgoing request before forwarding it to the next handler in the chain.
public struct AuthenticationMiddleware: ClientMiddleware {
  /// The Anthropic API version sent with every request.
  private static let anthropicVersion = "2023-06-01"

  /// The `x-api-key` header name, constructed once. `"x-api-key"` is a valid
  /// RFC 9110 token, so this is always non-`nil`.
  private static let apiKeyFieldName = HTTPField.Name("x-api-key")

  /// The `anthropic-version` header name, constructed once. `"anthropic-version"`
  /// is a valid RFC 9110 token, so this is always non-`nil`.
  private static let anthropicVersionFieldName = HTTPField.Name("anthropic-version")

  /// The Anthropic API key used to authenticate requests.
  private let apiKey: String

  /// Creates a middleware that authenticates requests with the given API key.
  /// - Parameter apiKey: The Anthropic API key to send in the `x-api-key` header.
  public init(apiKey: String) {
    self.apiKey = apiKey
  }

  /// Adds the Anthropic authentication headers, then forwards the request.
  ///
  /// Any `x-api-key` or `anthropic-version` header already present on the
  /// request is silently overwritten with this middleware's values.
  /// - Parameters:
  ///   - request: The outgoing HTTP request.
  ///   - body: The outgoing HTTP request body, if any.
  ///   - baseURL: The base URL of the server.
  ///   - operationID: The OpenAPI operation identifier for the request.
  ///   - next: The next handler in the middleware chain.
  /// - Returns: The HTTP response and body from the next handler.
  /// - Throws: Any error thrown by the `next` handler.
  public func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    var request = request
    if let apiKeyFieldName = Self.apiKeyFieldName {
      request.headerFields[apiKeyFieldName] = apiKey
    }
    if let anthropicVersionFieldName = Self.anthropicVersionFieldName {
      request.headerFields[anthropicVersionFieldName] = Self.anthropicVersion
    }
    return try await next(request, body, baseURL)
  }
}
