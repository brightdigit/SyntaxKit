//
//  Types.swift
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

@_spi(Generated) import OpenAPIRuntime

#if os(Linux)
  @preconcurrency import struct Foundation.URL
  @preconcurrency import struct Foundation.Data
  @preconcurrency import struct Foundation.Date
#else
  import struct Foundation.URL
  import struct Foundation.Data
  import struct Foundation.Date
#endif
/// A type that performs HTTP operations defined by the OpenAPI document.
package protocol APIProtocol: Sendable {
  /// Create a Message
  ///
  /// Send a structured list of input messages with text and/or image content, and the model will generate the next message in the conversation.
  ///
  /// The Messages API can be used for either single queries or stateless multi-turn conversations.
  ///
  /// - Remark: HTTP `POST /v1/messages`.
  /// - Remark: Generated from `#/paths//v1/messages/post(messages_post)`.
  func messages_post(_ input: Operations.messages_post.Input) async throws
    -> Operations.messages_post.Output
}

/// Convenience overloads for operation inputs.
extension APIProtocol {
  /// Create a Message
  ///
  /// Send a structured list of input messages with text and/or image content, and the model will generate the next message in the conversation.
  ///
  /// The Messages API can be used for either single queries or stateless multi-turn conversations.
  ///
  /// - Remark: HTTP `POST /v1/messages`.
  /// - Remark: Generated from `#/paths//v1/messages/post(messages_post)`.
  package func messages_post(
    headers: Operations.messages_post.Input.Headers = .init(),
    body: Operations.messages_post.Input.Body
  ) async throws -> Operations.messages_post.Output {
    try await messages_post(
      Operations.messages_post.Input(
        headers: headers,
        body: body
      ))
  }
}

/// Server URLs defined in the OpenAPI document.
package enum Servers {
  package enum Server1 {
    package static func url() throws -> Foundation.URL {
      try Foundation.URL(
        validatingOpenAPIServerURL: "https://api.anthropic.com",
        variables: []
      )
    }
  }
  @available(*, deprecated, renamed: "Servers.Server1.url")
  package static func server1() throws -> Foundation.URL {
    try Foundation.URL(
      validatingOpenAPIServerURL: "https://api.anthropic.com",
      variables: []
    )
  }
}

/// Types generated from the components section of the OpenAPI document.
package enum Components {
  /// Types generated from the `#/components/schemas` section of the OpenAPI document.
  package enum Schemas {
    /// - Remark: Generated from `#/components/schemas/APIError`.
    package struct APIError: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/APIError/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case api_error = "api_error"
      }
      /// - Remark: Generated from `#/components/schemas/APIError/type`.
      package var _type: Components.Schemas.APIError._typePayload
      /// - Remark: Generated from `#/components/schemas/APIError/message`.
      package var message: Swift.String
      /// Creates a new `APIError`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - message:
      package init(
        _type: Components.Schemas.APIError._typePayload,
        message: Swift.String
      ) {
        self._type = _type
        self.message = message
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case message
      }
    }
    /// - Remark: Generated from `#/components/schemas/AuthenticationError`.
    package struct AuthenticationError: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/AuthenticationError/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case authentication_error = "authentication_error"
      }
      /// - Remark: Generated from `#/components/schemas/AuthenticationError/type`.
      package var _type: Components.Schemas.AuthenticationError._typePayload
      /// - Remark: Generated from `#/components/schemas/AuthenticationError/message`.
      package var message: Swift.String
      /// Creates a new `AuthenticationError`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - message:
      package init(
        _type: Components.Schemas.AuthenticationError._typePayload,
        message: Swift.String
      ) {
        self._type = _type
        self.message = message
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case message
      }
    }
    /// - Remark: Generated from `#/components/schemas/Base64ImageSource`.
    package struct Base64ImageSource: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/Base64ImageSource/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case base64 = "base64"
      }
      /// - Remark: Generated from `#/components/schemas/Base64ImageSource/type`.
      package var _type: Components.Schemas.Base64ImageSource._typePayload
      /// - Remark: Generated from `#/components/schemas/Base64ImageSource/media_type`.
      @frozen package enum media_typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case image_sol_jpeg = "image/jpeg"
        case image_sol_png = "image/png"
        case image_sol_gif = "image/gif"
        case image_sol_webp = "image/webp"
      }
      /// - Remark: Generated from `#/components/schemas/Base64ImageSource/media_type`.
      package var media_type: Components.Schemas.Base64ImageSource.media_typePayload
      /// - Remark: Generated from `#/components/schemas/Base64ImageSource/data`.
      package var data: Swift.String
      /// Creates a new `Base64ImageSource`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - media_type:
      ///   - data:
      package init(
        _type: Components.Schemas.Base64ImageSource._typePayload,
        media_type: Components.Schemas.Base64ImageSource.media_typePayload,
        data: Swift.String
      ) {
        self._type = _type
        self.media_type = media_type
        self.data = data
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case media_type
        case data
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._type = try container.decode(
          Components.Schemas.Base64ImageSource._typePayload.self,
          forKey: ._type
        )
        self.media_type = try container.decode(
          Components.Schemas.Base64ImageSource.media_typePayload.self,
          forKey: .media_type
        )
        self.data = try container.decode(
          Swift.String.self,
          forKey: .data
        )
        try decoder.ensureNoAdditionalProperties(knownKeys: [
          "type",
          "media_type",
          "data",
        ])
      }
    }
    /// - Remark: Generated from `#/components/schemas/CreateMessageParams`.
    package struct CreateMessageParams: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/model`.
      package var model: Components.Schemas.Model
      /// Input messages.
      ///
      /// Our models are trained to operate on alternating `user` and `assistant` conversational turns. When creating a new `Message`, you specify the prior conversational turns with the `messages` parameter, and the model then generates the next `Message` in the conversation. Consecutive `user` or `assistant` turns in your request will be combined into a single turn.
      ///
      /// Each input message must be an object with a `role` and `content`. You can specify a single `user`-role message, or you can include multiple `user` and `assistant` messages.
      ///
      /// If the final message uses the `assistant` role, the response content will continue immediately from the content in that message. This can be used to constrain part of the model's response.
      ///
      /// Example with a single `user` message:
      ///
      /// ```json
      /// [{"role": "user", "content": "Hello, Claude"}]
      /// ```
      ///
      /// Example with multiple conversational turns:
      ///
      /// ```json
      /// [
      ///   {"role": "user", "content": "Hello there."},
      ///   {"role": "assistant", "content": "Hi, I'm Claude. How can I help you?"},
      ///   {"role": "user", "content": "Can you explain LLMs in plain English?"},
      /// ]
      /// ```
      ///
      /// Example with a partially-filled response from Claude:
      ///
      /// ```json
      /// [
      ///   {"role": "user", "content": "What's the Greek name for Sun? (A) Sol (B) Helios (C) Sun"},
      ///   {"role": "assistant", "content": "The best answer is ("},
      /// ]
      /// ```
      ///
      /// Each input message `content` may be either a single `string` or an array of content blocks, where each block has a specific `type`. Using a `string` for `content` is shorthand for an array of one content block of type `"text"`. The following input messages are equivalent:
      ///
      /// ```json
      /// {"role": "user", "content": "Hello, Claude"}
      /// ```
      ///
      /// ```json
      /// {"role": "user", "content": [{"type": "text", "text": "Hello, Claude"}]}
      /// ```
      ///
      /// Starting with Claude 3 models, you can also send image content blocks:
      ///
      /// ```json
      /// {"role": "user", "content": [
      ///   {
      ///     "type": "image",
      ///     "source": {
      ///       "type": "base64",
      ///       "media_type": "image/jpeg",
      ///       "data": "/9j/4AAQSkZJRg...",
      ///     }
      ///   },
      ///   {"type": "text", "text": "What is in this image?"}
      /// ]}
      /// ```
      ///
      /// We currently support the `base64` source type for images, and the `image/jpeg`, `image/png`, `image/gif`, and `image/webp` media types.
      ///
      /// See [examples](https://docs.anthropic.com/en/api/messages-examples#vision) for more input examples.
      ///
      /// Note that if you want to include a [system prompt](https://docs.anthropic.com/en/docs/system-prompts), you can use the top-level `system` parameter — there is no `"system"` role for input messages in the Messages API.
      ///
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/messages`.
      package var messages: [Components.Schemas.InputMessage]
      /// The maximum number of tokens to generate before stopping.
      ///
      /// Note that our models may stop _before_ reaching this maximum. This parameter only specifies the absolute maximum number of tokens to generate.
      ///
      /// Different models have different maximum values for this parameter.  See [models](https://docs.anthropic.com/en/docs/models-overview) for details.
      ///
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/max_tokens`.
      package var max_tokens: Swift.Int
      /// An object describing metadata about the request.
      ///
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/metadata`.
      package struct metadataPayload: Codable, Hashable, Sendable {
        /// - Remark: Generated from `#/components/schemas/CreateMessageParams/metadata/value1`.
        package var value1: Components.Schemas.Metadata
        /// Creates a new `metadataPayload`.
        ///
        /// - Parameters:
        ///   - value1:
        package init(value1: Components.Schemas.Metadata) {
          self.value1 = value1
        }
        package init(from decoder: any Swift.Decoder) throws {
          self.value1 = try .init(from: decoder)
        }
        package func encode(to encoder: any Swift.Encoder) throws {
          try self.value1.encode(to: encoder)
        }
      }
      /// An object describing metadata about the request.
      ///
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/metadata`.
      package var metadata: Components.Schemas.CreateMessageParams.metadataPayload?
      /// Custom text sequences that will cause the model to stop generating.
      ///
      /// Our models will normally stop when they have naturally completed their turn, which will result in a response `stop_reason` of `"end_turn"`.
      ///
      /// If you want the model to stop generating when it encounters custom strings of text, you can use the `stop_sequences` parameter. If the model encounters one of the custom sequences, the response `stop_reason` value will be `"stop_sequence"` and the response `stop_sequence` value will contain the matched stop sequence.
      ///
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/stop_sequences`.
      package var stop_sequences: [Swift.String]?
      /// Whether to incrementally stream the response using server-sent events.
      ///
      /// See [streaming](https://docs.anthropic.com/en/api/messages-streaming) for details.
      ///
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/stream`.
      package var stream: Swift.Bool?
      /// System prompt.
      ///
      /// A system prompt is a way of providing context and instructions to Claude, such as specifying a particular goal or role. See our [guide to system prompts](https://docs.anthropic.com/en/docs/system-prompts).
      ///
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/system`.
      package struct systemPayload: Codable, Hashable, Sendable {
        /// - Remark: Generated from `#/components/schemas/CreateMessageParams/system/value1`.
        package var value1: Swift.String?
        /// - Remark: Generated from `#/components/schemas/CreateMessageParams/system/value2`.
        package var value2: [Components.Schemas.RequestTextBlock]?
        /// Creates a new `systemPayload`.
        ///
        /// - Parameters:
        ///   - value1:
        ///   - value2:
        package init(
          value1: Swift.String? = nil,
          value2: [Components.Schemas.RequestTextBlock]? = nil
        ) {
          self.value1 = value1
          self.value2 = value2
        }
        package init(from decoder: any Swift.Decoder) throws {
          var errors: [any Swift.Error] = []
          do {
            self.value1 = try decoder.decodeFromSingleValueContainer()
          } catch {
            errors.append(error)
          }
          do {
            self.value2 = try decoder.decodeFromSingleValueContainer()
          } catch {
            errors.append(error)
          }
          try Swift.DecodingError.verifyAtLeastOneSchemaIsNotNil(
            [
              self.value1,
              self.value2,
            ],
            type: Self.self,
            codingPath: decoder.codingPath,
            errors: errors
          )
        }
        package func encode(to encoder: any Swift.Encoder) throws {
          try encoder.encodeFirstNonNilValueToSingleValueContainer([
            self.value1,
            self.value2,
          ])
        }
      }
      /// System prompt.
      ///
      /// A system prompt is a way of providing context and instructions to Claude, such as specifying a particular goal or role. See our [guide to system prompts](https://docs.anthropic.com/en/docs/system-prompts).
      ///
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/system`.
      package var system: Components.Schemas.CreateMessageParams.systemPayload?
      /// Amount of randomness injected into the response.
      ///
      /// Defaults to `1.0`. Ranges from `0.0` to `1.0`. Use `temperature` closer to `0.0` for analytical / multiple choice, and closer to `1.0` for creative and generative tasks.
      ///
      /// Note that even with `temperature` of `0.0`, the results will not be fully deterministic.
      ///
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/temperature`.
      package var temperature: Swift.Double?
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/tool_choice`.
      package var tool_choice: Components.Schemas.ToolChoice?
      /// Definitions of tools that the model may use.
      ///
      /// If you include `tools` in your API request, the model may return `tool_use` content blocks that represent the model's use of those tools. You can then run those tools using the tool input generated by the model and then optionally return results back to the model using `tool_result` content blocks.
      ///
      /// Each tool definition includes:
      ///
      /// * `name`: Name of the tool.
      /// * `description`: Optional, but strongly-recommended description of the tool.
      /// * `input_schema`: [JSON schema](https://json-schema.org/) for the tool `input` shape that the model will produce in `tool_use` output content blocks.
      ///
      /// For example, if you defined `tools` as:
      ///
      /// ```json
      /// [
      ///   {
      ///     "name": "get_stock_price",
      ///     "description": "Get the current stock price for a given ticker symbol.",
      ///     "input_schema": {
      ///       "type": "object",
      ///       "properties": {
      ///         "ticker": {
      ///           "type": "string",
      ///           "description": "The stock ticker symbol, e.g. AAPL for Apple Inc."
      ///         }
      ///       },
      ///       "required": ["ticker"]
      ///     }
      ///   }
      /// ]
      /// ```
      ///
      /// And then asked the model "What's the S&P 500 at today?", the model might produce `tool_use` content blocks in the response like this:
      ///
      /// ```json
      /// [
      ///   {
      ///     "type": "tool_use",
      ///     "id": "toolu_01D7FLrfh4GYq7yT1ULFeyMV",
      ///     "name": "get_stock_price",
      ///     "input": { "ticker": "^GSPC" }
      ///   }
      /// ]
      /// ```
      ///
      /// You might then run your `get_stock_price` tool with `{"ticker": "^GSPC"}` as an input, and return the following back to the model in a subsequent `user` message:
      ///
      /// ```json
      /// [
      ///   {
      ///     "type": "tool_result",
      ///     "tool_use_id": "toolu_01D7FLrfh4GYq7yT1ULFeyMV",
      ///     "content": "259.75 USD"
      ///   }
      /// ]
      /// ```
      ///
      /// Tools can be used for workflows that include running client-side tools and functions, or more generally whenever you want the model to produce a particular JSON structure of output.
      ///
      /// See our [guide](https://docs.anthropic.com/en/docs/tool-use) for more details.
      ///
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/tools`.
      package var tools: [Components.Schemas.Tool]?
      /// Only sample from the top K options for each subsequent token.
      ///
      /// Used to remove "long tail" low probability responses. [Learn more technical details here](https://towardsdatascience.com/how-to-sample-from-language-models-682bceb97277).
      ///
      /// Recommended for advanced use cases only. You usually only need to use `temperature`.
      ///
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/top_k`.
      package var top_k: Swift.Int?
      /// Use nucleus sampling.
      ///
      /// In nucleus sampling, we compute the cumulative distribution over all the options for each subsequent token in decreasing probability order and cut it off once it reaches a particular probability specified by `top_p`. You should either alter `temperature` or `top_p`, but not both.
      ///
      /// Recommended for advanced use cases only. You usually only need to use `temperature`.
      ///
      /// - Remark: Generated from `#/components/schemas/CreateMessageParams/top_p`.
      package var top_p: Swift.Double?
      /// Creates a new `CreateMessageParams`.
      ///
      /// - Parameters:
      ///   - model:
      ///   - messages: Input messages.
      ///   - max_tokens: The maximum number of tokens to generate before stopping.
      ///   - metadata: An object describing metadata about the request.
      ///   - stop_sequences: Custom text sequences that will cause the model to stop generating.
      ///   - stream: Whether to incrementally stream the response using server-sent events.
      ///   - system: System prompt.
      ///   - temperature: Amount of randomness injected into the response.
      ///   - tool_choice:
      ///   - tools: Definitions of tools that the model may use.
      ///   - top_k: Only sample from the top K options for each subsequent token.
      ///   - top_p: Use nucleus sampling.
      package init(
        model: Components.Schemas.Model,
        messages: [Components.Schemas.InputMessage],
        max_tokens: Swift.Int,
        metadata: Components.Schemas.CreateMessageParams.metadataPayload? = nil,
        stop_sequences: [Swift.String]? = nil,
        stream: Swift.Bool? = nil,
        system: Components.Schemas.CreateMessageParams.systemPayload? = nil,
        temperature: Swift.Double? = nil,
        tool_choice: Components.Schemas.ToolChoice? = nil,
        tools: [Components.Schemas.Tool]? = nil,
        top_k: Swift.Int? = nil,
        top_p: Swift.Double? = nil
      ) {
        self.model = model
        self.messages = messages
        self.max_tokens = max_tokens
        self.metadata = metadata
        self.stop_sequences = stop_sequences
        self.stream = stream
        self.system = system
        self.temperature = temperature
        self.tool_choice = tool_choice
        self.tools = tools
        self.top_k = top_k
        self.top_p = top_p
      }
      package enum CodingKeys: String, CodingKey {
        case model
        case messages
        case max_tokens
        case metadata
        case stop_sequences
        case stream
        case system
        case temperature
        case tool_choice
        case tools
        case top_k
        case top_p
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.model = try container.decode(
          Components.Schemas.Model.self,
          forKey: .model
        )
        self.messages = try container.decode(
          [Components.Schemas.InputMessage].self,
          forKey: .messages
        )
        self.max_tokens = try container.decode(
          Swift.Int.self,
          forKey: .max_tokens
        )
        self.metadata = try container.decodeIfPresent(
          Components.Schemas.CreateMessageParams.metadataPayload.self,
          forKey: .metadata
        )
        self.stop_sequences = try container.decodeIfPresent(
          [Swift.String].self,
          forKey: .stop_sequences
        )
        self.stream = try container.decodeIfPresent(
          Swift.Bool.self,
          forKey: .stream
        )
        self.system = try container.decodeIfPresent(
          Components.Schemas.CreateMessageParams.systemPayload.self,
          forKey: .system
        )
        self.temperature = try container.decodeIfPresent(
          Swift.Double.self,
          forKey: .temperature
        )
        self.tool_choice = try container.decodeIfPresent(
          Components.Schemas.ToolChoice.self,
          forKey: .tool_choice
        )
        self.tools = try container.decodeIfPresent(
          [Components.Schemas.Tool].self,
          forKey: .tools
        )
        self.top_k = try container.decodeIfPresent(
          Swift.Int.self,
          forKey: .top_k
        )
        self.top_p = try container.decodeIfPresent(
          Swift.Double.self,
          forKey: .top_p
        )
        try decoder.ensureNoAdditionalProperties(knownKeys: [
          "model",
          "messages",
          "max_tokens",
          "metadata",
          "stop_sequences",
          "stream",
          "system",
          "temperature",
          "tool_choice",
          "tools",
          "top_k",
          "top_p",
        ])
      }
    }
    /// - Remark: Generated from `#/components/schemas/ErrorResponse`.
    package struct ErrorResponse: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/ErrorResponse/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case error = "error"
      }
      /// - Remark: Generated from `#/components/schemas/ErrorResponse/type`.
      package var _type: Components.Schemas.ErrorResponse._typePayload
      /// - Remark: Generated from `#/components/schemas/ErrorResponse/error`.
      @frozen package enum errorPayload: Codable, Hashable, Sendable {
        /// - Remark: Generated from `#/components/schemas/ErrorResponse/error/APIError`.
        case api_error(Components.Schemas.APIError)
        /// - Remark: Generated from `#/components/schemas/ErrorResponse/error/AuthenticationError`.
        case authentication_error(Components.Schemas.AuthenticationError)
        /// - Remark: Generated from `#/components/schemas/ErrorResponse/error/InvalidRequestError`.
        case invalid_request_error(Components.Schemas.InvalidRequestError)
        /// - Remark: Generated from `#/components/schemas/ErrorResponse/error/NotFoundError`.
        case not_found_error(Components.Schemas.NotFoundError)
        /// - Remark: Generated from `#/components/schemas/ErrorResponse/error/OverloadedError`.
        case overloaded_error(Components.Schemas.OverloadedError)
        /// - Remark: Generated from `#/components/schemas/ErrorResponse/error/PermissionError`.
        case permission_error(Components.Schemas.PermissionError)
        /// - Remark: Generated from `#/components/schemas/ErrorResponse/error/RateLimitError`.
        case rate_limit_error(Components.Schemas.RateLimitError)
        package enum CodingKeys: String, CodingKey {
          case _type = "type"
        }
        package init(from decoder: any Swift.Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let discriminator = try container.decode(
            Swift.String.self,
            forKey: ._type
          )
          switch discriminator {
          case "api_error":
            self = .api_error(try .init(from: decoder))
          case "authentication_error":
            self = .authentication_error(try .init(from: decoder))
          case "invalid_request_error":
            self = .invalid_request_error(try .init(from: decoder))
          case "not_found_error":
            self = .not_found_error(try .init(from: decoder))
          case "overloaded_error":
            self = .overloaded_error(try .init(from: decoder))
          case "permission_error":
            self = .permission_error(try .init(from: decoder))
          case "rate_limit_error":
            self = .rate_limit_error(try .init(from: decoder))
          default:
            throw Swift.DecodingError.unknownOneOfDiscriminator(
              discriminatorKey: CodingKeys._type,
              discriminatorValue: discriminator,
              codingPath: decoder.codingPath
            )
          }
        }
        package func encode(to encoder: any Swift.Encoder) throws {
          switch self {
          case .api_error(let value):
            try value.encode(to: encoder)
          case .authentication_error(let value):
            try value.encode(to: encoder)
          case .invalid_request_error(let value):
            try value.encode(to: encoder)
          case .not_found_error(let value):
            try value.encode(to: encoder)
          case .overloaded_error(let value):
            try value.encode(to: encoder)
          case .permission_error(let value):
            try value.encode(to: encoder)
          case .rate_limit_error(let value):
            try value.encode(to: encoder)
          }
        }
      }
      /// - Remark: Generated from `#/components/schemas/ErrorResponse/error`.
      package var error: Components.Schemas.ErrorResponse.errorPayload
      /// Creates a new `ErrorResponse`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - error:
      package init(
        _type: Components.Schemas.ErrorResponse._typePayload,
        error: Components.Schemas.ErrorResponse.errorPayload
      ) {
        self._type = _type
        self.error = error
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case error
      }
    }
    /// - Remark: Generated from `#/components/schemas/InputMessage`.
    package struct InputMessage: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/InputMessage/role`.
      @frozen package enum rolePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case user = "user"
        case assistant = "assistant"
      }
      /// - Remark: Generated from `#/components/schemas/InputMessage/role`.
      package var role: Components.Schemas.InputMessage.rolePayload
      /// - Remark: Generated from `#/components/schemas/InputMessage/content`.
      package struct contentPayload: Codable, Hashable, Sendable {
        /// - Remark: Generated from `#/components/schemas/InputMessage/content/value1`.
        package var value1: Swift.String?
        /// - Remark: Generated from `#/components/schemas/InputMessage/content/Value2Payload`.
        @frozen package enum Value2PayloadPayload: Codable, Hashable, Sendable {
          /// - Remark: Generated from `#/components/schemas/InputMessage/content/Value2Payload/RequestImageBlock`.
          case image(Components.Schemas.RequestImageBlock)
          /// - Remark: Generated from `#/components/schemas/InputMessage/content/Value2Payload/RequestTextBlock`.
          case text(Components.Schemas.RequestTextBlock)
          /// - Remark: Generated from `#/components/schemas/InputMessage/content/Value2Payload/RequestToolResultBlock`.
          case tool_result(Components.Schemas.RequestToolResultBlock)
          /// - Remark: Generated from `#/components/schemas/InputMessage/content/Value2Payload/RequestToolUseBlock`.
          case tool_use(Components.Schemas.RequestToolUseBlock)
          package enum CodingKeys: String, CodingKey {
            case _type = "type"
          }
          package init(from decoder: any Swift.Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let discriminator = try container.decode(
              Swift.String.self,
              forKey: ._type
            )
            switch discriminator {
            case "image":
              self = .image(try .init(from: decoder))
            case "text":
              self = .text(try .init(from: decoder))
            case "tool_result":
              self = .tool_result(try .init(from: decoder))
            case "tool_use":
              self = .tool_use(try .init(from: decoder))
            default:
              throw Swift.DecodingError.unknownOneOfDiscriminator(
                discriminatorKey: CodingKeys._type,
                discriminatorValue: discriminator,
                codingPath: decoder.codingPath
              )
            }
          }
          package func encode(to encoder: any Swift.Encoder) throws {
            switch self {
            case .image(let value):
              try value.encode(to: encoder)
            case .text(let value):
              try value.encode(to: encoder)
            case .tool_result(let value):
              try value.encode(to: encoder)
            case .tool_use(let value):
              try value.encode(to: encoder)
            }
          }
        }
        /// - Remark: Generated from `#/components/schemas/InputMessage/content/value2`.
        package typealias Value2Payload = [Components.Schemas.InputMessage.contentPayload
          .Value2PayloadPayload]
        /// - Remark: Generated from `#/components/schemas/InputMessage/content/value2`.
        package var value2: Components.Schemas.InputMessage.contentPayload.Value2Payload?
        /// Creates a new `contentPayload`.
        ///
        /// - Parameters:
        ///   - value1:
        ///   - value2:
        package init(
          value1: Swift.String? = nil,
          value2: Components.Schemas.InputMessage.contentPayload.Value2Payload? = nil
        ) {
          self.value1 = value1
          self.value2 = value2
        }
        package init(from decoder: any Swift.Decoder) throws {
          var errors: [any Swift.Error] = []
          do {
            self.value1 = try decoder.decodeFromSingleValueContainer()
          } catch {
            errors.append(error)
          }
          do {
            self.value2 = try decoder.decodeFromSingleValueContainer()
          } catch {
            errors.append(error)
          }
          try Swift.DecodingError.verifyAtLeastOneSchemaIsNotNil(
            [
              self.value1,
              self.value2,
            ],
            type: Self.self,
            codingPath: decoder.codingPath,
            errors: errors
          )
        }
        package func encode(to encoder: any Swift.Encoder) throws {
          try encoder.encodeFirstNonNilValueToSingleValueContainer([
            self.value1,
            self.value2,
          ])
        }
      }
      /// - Remark: Generated from `#/components/schemas/InputMessage/content`.
      package var content: Components.Schemas.InputMessage.contentPayload
      /// Creates a new `InputMessage`.
      ///
      /// - Parameters:
      ///   - role:
      ///   - content:
      package init(
        role: Components.Schemas.InputMessage.rolePayload,
        content: Components.Schemas.InputMessage.contentPayload
      ) {
        self.role = role
        self.content = content
      }
      package enum CodingKeys: String, CodingKey {
        case role
        case content
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.role = try container.decode(
          Components.Schemas.InputMessage.rolePayload.self,
          forKey: .role
        )
        self.content = try container.decode(
          Components.Schemas.InputMessage.contentPayload.self,
          forKey: .content
        )
        try decoder.ensureNoAdditionalProperties(knownKeys: [
          "role",
          "content",
        ])
      }
    }
    /// - Remark: Generated from `#/components/schemas/InputSchema`.
    package struct InputSchema: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/InputSchema/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case object = "object"
      }
      /// - Remark: Generated from `#/components/schemas/InputSchema/type`.
      package var _type: Components.Schemas.InputSchema._typePayload
      /// A container of undocumented properties.
      package var additionalProperties: OpenAPIRuntime.OpenAPIObjectContainer
      /// Creates a new `InputSchema`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - additionalProperties: A container of undocumented properties.
      package init(
        _type: Components.Schemas.InputSchema._typePayload,
        additionalProperties: OpenAPIRuntime.OpenAPIObjectContainer = .init()
      ) {
        self._type = _type
        self.additionalProperties = additionalProperties
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._type = try container.decode(
          Components.Schemas.InputSchema._typePayload.self,
          forKey: ._type
        )
        additionalProperties = try decoder.decodeAdditionalProperties(knownKeys: [
          "type"
        ])
      }
      package func encode(to encoder: any Swift.Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(
          self._type,
          forKey: ._type
        )
        try encoder.encodeAdditionalProperties(additionalProperties)
      }
    }
    /// - Remark: Generated from `#/components/schemas/InvalidRequestError`.
    package struct InvalidRequestError: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/InvalidRequestError/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case invalid_request_error = "invalid_request_error"
      }
      /// - Remark: Generated from `#/components/schemas/InvalidRequestError/type`.
      package var _type: Components.Schemas.InvalidRequestError._typePayload
      /// - Remark: Generated from `#/components/schemas/InvalidRequestError/message`.
      package var message: Swift.String
      /// Creates a new `InvalidRequestError`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - message:
      package init(
        _type: Components.Schemas.InvalidRequestError._typePayload,
        message: Swift.String
      ) {
        self._type = _type
        self.message = message
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case message
      }
    }
    /// - Remark: Generated from `#/components/schemas/Message`.
    package struct Message: Codable, Hashable, Sendable {
      /// Unique object identifier.
      ///
      /// The format and length of IDs may change over time.
      ///
      /// - Remark: Generated from `#/components/schemas/Message/id`.
      package var id: Swift.String
      /// Object type.
      ///
      /// For Messages, this is always `"message"`.
      ///
      /// - Remark: Generated from `#/components/schemas/Message/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case message = "message"
      }
      /// Object type.
      ///
      /// For Messages, this is always `"message"`.
      ///
      /// - Remark: Generated from `#/components/schemas/Message/type`.
      package var _type: Components.Schemas.Message._typePayload
      /// Conversational role of the generated message.
      ///
      /// This will always be `"assistant"`.
      ///
      /// - Remark: Generated from `#/components/schemas/Message/role`.
      @frozen package enum rolePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case assistant = "assistant"
      }
      /// Conversational role of the generated message.
      ///
      /// This will always be `"assistant"`.
      ///
      /// - Remark: Generated from `#/components/schemas/Message/role`.
      package var role: Components.Schemas.Message.rolePayload
      /// Content generated by the model.
      ///
      /// This is an array of content blocks, each of which has a `type` that determines its shape.
      ///
      /// Example:
      ///
      /// ```json
      /// [{"type": "text", "text": "Hi, I'm Claude."}]
      /// ```
      ///
      /// If the request input `messages` ended with an `assistant` turn, then the response `content` will continue directly from that last turn. You can use this to constrain the model's output.
      ///
      /// For example, if the input `messages` were:
      /// ```json
      /// [
      ///   {"role": "user", "content": "What's the Greek name for Sun? (A) Sol (B) Helios (C) Sun"},
      ///   {"role": "assistant", "content": "The best answer is ("}
      /// ]
      /// ```
      ///
      /// Then the response `content` might be:
      ///
      /// ```json
      /// [{"type": "text", "text": "B)"}]
      /// ```
      ///
      /// - Remark: Generated from `#/components/schemas/Message/content`.
      package var content: [Components.Schemas.ContentBlock]
      /// - Remark: Generated from `#/components/schemas/Message/model`.
      package var model: Components.Schemas.Model
      /// Billing and rate-limit usage.
      ///
      /// Anthropic's API bills and rate-limits by token counts, as tokens represent the underlying cost to our systems.
      ///
      /// Under the hood, the API transforms requests into a format suitable for the model. The model's output then goes through a parsing stage before becoming an API response. As a result, the token counts in `usage` will not match one-to-one with the exact visible content of an API request or response.
      ///
      /// For example, `output_tokens` will be non-zero, even for an empty string response from Claude.
      ///
      /// - Remark: Generated from `#/components/schemas/Message/usage`.
      package struct usagePayload: Codable, Hashable, Sendable {
        /// - Remark: Generated from `#/components/schemas/Message/usage/value1`.
        package var value1: Components.Schemas.Usage
        /// Creates a new `usagePayload`.
        ///
        /// - Parameters:
        ///   - value1:
        package init(value1: Components.Schemas.Usage) {
          self.value1 = value1
        }
        package init(from decoder: any Swift.Decoder) throws {
          self.value1 = try .init(from: decoder)
        }
        package func encode(to encoder: any Swift.Encoder) throws {
          try self.value1.encode(to: encoder)
        }
      }
      /// Billing and rate-limit usage.
      ///
      /// Anthropic's API bills and rate-limits by token counts, as tokens represent the underlying cost to our systems.
      ///
      /// Under the hood, the API transforms requests into a format suitable for the model. The model's output then goes through a parsing stage before becoming an API response. As a result, the token counts in `usage` will not match one-to-one with the exact visible content of an API request or response.
      ///
      /// For example, `output_tokens` will be non-zero, even for an empty string response from Claude.
      ///
      /// - Remark: Generated from `#/components/schemas/Message/usage`.
      package var usage: Components.Schemas.Message.usagePayload
      /// Creates a new `Message`.
      ///
      /// - Parameters:
      ///   - id: Unique object identifier.
      ///   - _type: Object type.
      ///   - role: Conversational role of the generated message.
      ///   - content: Content generated by the model.
      ///   - model:
      ///   - usage: Billing and rate-limit usage.
      package init(
        id: Swift.String,
        _type: Components.Schemas.Message._typePayload,
        role: Components.Schemas.Message.rolePayload,
        content: [Components.Schemas.ContentBlock],
        model: Components.Schemas.Model,
        usage: Components.Schemas.Message.usagePayload
      ) {
        self.id = id
        self._type = _type
        self.role = role
        self.content = content
        self.model = model
        self.usage = usage
      }
      package enum CodingKeys: String, CodingKey {
        case id
        case _type = "type"
        case role
        case content
        case model
        case usage
      }
    }
    /// - Remark: Generated from `#/components/schemas/Metadata`.
    package struct Metadata: Codable, Hashable, Sendable {
      /// Creates a new `Metadata`.
      package init() {}
      package init(from decoder: any Swift.Decoder) throws {
        try decoder.ensureNoAdditionalProperties(knownKeys: [])
      }
    }
    /// - Remark: Generated from `#/components/schemas/NotFoundError`.
    package struct NotFoundError: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/NotFoundError/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case not_found_error = "not_found_error"
      }
      /// - Remark: Generated from `#/components/schemas/NotFoundError/type`.
      package var _type: Components.Schemas.NotFoundError._typePayload
      /// - Remark: Generated from `#/components/schemas/NotFoundError/message`.
      package var message: Swift.String
      /// Creates a new `NotFoundError`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - message:
      package init(
        _type: Components.Schemas.NotFoundError._typePayload,
        message: Swift.String
      ) {
        self._type = _type
        self.message = message
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case message
      }
    }
    /// - Remark: Generated from `#/components/schemas/OverloadedError`.
    package struct OverloadedError: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/OverloadedError/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case overloaded_error = "overloaded_error"
      }
      /// - Remark: Generated from `#/components/schemas/OverloadedError/type`.
      package var _type: Components.Schemas.OverloadedError._typePayload
      /// - Remark: Generated from `#/components/schemas/OverloadedError/message`.
      package var message: Swift.String
      /// Creates a new `OverloadedError`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - message:
      package init(
        _type: Components.Schemas.OverloadedError._typePayload,
        message: Swift.String
      ) {
        self._type = _type
        self.message = message
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case message
      }
    }
    /// - Remark: Generated from `#/components/schemas/PermissionError`.
    package struct PermissionError: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/PermissionError/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case permission_error = "permission_error"
      }
      /// - Remark: Generated from `#/components/schemas/PermissionError/type`.
      package var _type: Components.Schemas.PermissionError._typePayload
      /// - Remark: Generated from `#/components/schemas/PermissionError/message`.
      package var message: Swift.String
      /// Creates a new `PermissionError`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - message:
      package init(
        _type: Components.Schemas.PermissionError._typePayload,
        message: Swift.String
      ) {
        self._type = _type
        self.message = message
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case message
      }
    }
    /// - Remark: Generated from `#/components/schemas/RateLimitError`.
    package struct RateLimitError: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/RateLimitError/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case rate_limit_error = "rate_limit_error"
      }
      /// - Remark: Generated from `#/components/schemas/RateLimitError/type`.
      package var _type: Components.Schemas.RateLimitError._typePayload
      /// - Remark: Generated from `#/components/schemas/RateLimitError/message`.
      package var message: Swift.String
      /// Creates a new `RateLimitError`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - message:
      package init(
        _type: Components.Schemas.RateLimitError._typePayload,
        message: Swift.String
      ) {
        self._type = _type
        self.message = message
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case message
      }
    }
    /// - Remark: Generated from `#/components/schemas/RequestImageBlock`.
    package struct RequestImageBlock: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/RequestImageBlock/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case image = "image"
      }
      /// - Remark: Generated from `#/components/schemas/RequestImageBlock/type`.
      package var _type: Components.Schemas.RequestImageBlock._typePayload
      /// - Remark: Generated from `#/components/schemas/RequestImageBlock/source`.
      @frozen package enum sourcePayload: Codable, Hashable, Sendable {
        /// - Remark: Generated from `#/components/schemas/RequestImageBlock/source/Base64ImageSource`.
        case base64(Components.Schemas.Base64ImageSource)
        package enum CodingKeys: String, CodingKey {
          case _type = "type"
        }
        package init(from decoder: any Swift.Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let discriminator = try container.decode(
            Swift.String.self,
            forKey: ._type
          )
          switch discriminator {
          case "base64":
            self = .base64(try .init(from: decoder))
          default:
            throw Swift.DecodingError.unknownOneOfDiscriminator(
              discriminatorKey: CodingKeys._type,
              discriminatorValue: discriminator,
              codingPath: decoder.codingPath
            )
          }
        }
        package func encode(to encoder: any Swift.Encoder) throws {
          switch self {
          case .base64(let value):
            try value.encode(to: encoder)
          }
        }
      }
      /// - Remark: Generated from `#/components/schemas/RequestImageBlock/source`.
      package var source: Components.Schemas.RequestImageBlock.sourcePayload
      /// Creates a new `RequestImageBlock`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - source:
      package init(
        _type: Components.Schemas.RequestImageBlock._typePayload,
        source: Components.Schemas.RequestImageBlock.sourcePayload
      ) {
        self._type = _type
        self.source = source
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case source
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._type = try container.decode(
          Components.Schemas.RequestImageBlock._typePayload.self,
          forKey: ._type
        )
        self.source = try container.decode(
          Components.Schemas.RequestImageBlock.sourcePayload.self,
          forKey: .source
        )
        try decoder.ensureNoAdditionalProperties(knownKeys: [
          "type",
          "source",
        ])
      }
    }
    /// - Remark: Generated from `#/components/schemas/RequestTextBlock`.
    package struct RequestTextBlock: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/RequestTextBlock/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case text = "text"
      }
      /// - Remark: Generated from `#/components/schemas/RequestTextBlock/type`.
      package var _type: Components.Schemas.RequestTextBlock._typePayload
      /// - Remark: Generated from `#/components/schemas/RequestTextBlock/text`.
      package var text: Swift.String
      /// Creates a new `RequestTextBlock`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - text:
      package init(
        _type: Components.Schemas.RequestTextBlock._typePayload,
        text: Swift.String
      ) {
        self._type = _type
        self.text = text
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case text
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._type = try container.decode(
          Components.Schemas.RequestTextBlock._typePayload.self,
          forKey: ._type
        )
        self.text = try container.decode(
          Swift.String.self,
          forKey: .text
        )
        try decoder.ensureNoAdditionalProperties(knownKeys: [
          "type",
          "text",
        ])
      }
    }
    /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock`.
    package struct RequestToolResultBlock: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case tool_result = "tool_result"
      }
      /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock/type`.
      package var _type: Components.Schemas.RequestToolResultBlock._typePayload
      /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock/tool_use_id`.
      package var tool_use_id: Swift.String
      /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock/is_error`.
      package var is_error: Swift.Bool?
      /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock/content`.
      package struct contentPayload: Codable, Hashable, Sendable {
        /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock/content/value1`.
        package var value1: Swift.String?
        /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock/content/Value2Payload`.
        @frozen package enum Value2PayloadPayload: Codable, Hashable, Sendable {
          /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock/content/Value2Payload/RequestImageBlock`.
          case image(Components.Schemas.RequestImageBlock)
          /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock/content/Value2Payload/RequestTextBlock`.
          case text(Components.Schemas.RequestTextBlock)
          package enum CodingKeys: String, CodingKey {
            case _type = "type"
          }
          package init(from decoder: any Swift.Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let discriminator = try container.decode(
              Swift.String.self,
              forKey: ._type
            )
            switch discriminator {
            case "image":
              self = .image(try .init(from: decoder))
            case "text":
              self = .text(try .init(from: decoder))
            default:
              throw Swift.DecodingError.unknownOneOfDiscriminator(
                discriminatorKey: CodingKeys._type,
                discriminatorValue: discriminator,
                codingPath: decoder.codingPath
              )
            }
          }
          package func encode(to encoder: any Swift.Encoder) throws {
            switch self {
            case .image(let value):
              try value.encode(to: encoder)
            case .text(let value):
              try value.encode(to: encoder)
            }
          }
        }
        /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock/content/value2`.
        package typealias Value2Payload = [Components.Schemas.RequestToolResultBlock.contentPayload
          .Value2PayloadPayload]
        /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock/content/value2`.
        package var value2: Components.Schemas.RequestToolResultBlock.contentPayload.Value2Payload?
        /// Creates a new `contentPayload`.
        ///
        /// - Parameters:
        ///   - value1:
        ///   - value2:
        package init(
          value1: Swift.String? = nil,
          value2: Components.Schemas.RequestToolResultBlock.contentPayload.Value2Payload? = nil
        ) {
          self.value1 = value1
          self.value2 = value2
        }
        package init(from decoder: any Swift.Decoder) throws {
          var errors: [any Swift.Error] = []
          do {
            self.value1 = try decoder.decodeFromSingleValueContainer()
          } catch {
            errors.append(error)
          }
          do {
            self.value2 = try decoder.decodeFromSingleValueContainer()
          } catch {
            errors.append(error)
          }
          try Swift.DecodingError.verifyAtLeastOneSchemaIsNotNil(
            [
              self.value1,
              self.value2,
            ],
            type: Self.self,
            codingPath: decoder.codingPath,
            errors: errors
          )
        }
        package func encode(to encoder: any Swift.Encoder) throws {
          try encoder.encodeFirstNonNilValueToSingleValueContainer([
            self.value1,
            self.value2,
          ])
        }
      }
      /// - Remark: Generated from `#/components/schemas/RequestToolResultBlock/content`.
      package var content: Components.Schemas.RequestToolResultBlock.contentPayload?
      /// Creates a new `RequestToolResultBlock`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - tool_use_id:
      ///   - is_error:
      ///   - content:
      package init(
        _type: Components.Schemas.RequestToolResultBlock._typePayload,
        tool_use_id: Swift.String,
        is_error: Swift.Bool? = nil,
        content: Components.Schemas.RequestToolResultBlock.contentPayload? = nil
      ) {
        self._type = _type
        self.tool_use_id = tool_use_id
        self.is_error = is_error
        self.content = content
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case tool_use_id
        case is_error
        case content
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._type = try container.decode(
          Components.Schemas.RequestToolResultBlock._typePayload.self,
          forKey: ._type
        )
        self.tool_use_id = try container.decode(
          Swift.String.self,
          forKey: .tool_use_id
        )
        self.is_error = try container.decodeIfPresent(
          Swift.Bool.self,
          forKey: .is_error
        )
        self.content = try container.decodeIfPresent(
          Components.Schemas.RequestToolResultBlock.contentPayload.self,
          forKey: .content
        )
        try decoder.ensureNoAdditionalProperties(knownKeys: [
          "type",
          "tool_use_id",
          "is_error",
          "content",
        ])
      }
    }
    /// - Remark: Generated from `#/components/schemas/RequestToolUseBlock`.
    package struct RequestToolUseBlock: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/RequestToolUseBlock/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case tool_use = "tool_use"
      }
      /// - Remark: Generated from `#/components/schemas/RequestToolUseBlock/type`.
      package var _type: Components.Schemas.RequestToolUseBlock._typePayload
      /// - Remark: Generated from `#/components/schemas/RequestToolUseBlock/id`.
      package var id: Swift.String
      /// - Remark: Generated from `#/components/schemas/RequestToolUseBlock/name`.
      package var name: Swift.String
      /// - Remark: Generated from `#/components/schemas/RequestToolUseBlock/input`.
      package var input: OpenAPIRuntime.OpenAPIObjectContainer
      /// Creates a new `RequestToolUseBlock`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - id:
      ///   - name:
      ///   - input:
      package init(
        _type: Components.Schemas.RequestToolUseBlock._typePayload,
        id: Swift.String,
        name: Swift.String,
        input: OpenAPIRuntime.OpenAPIObjectContainer
      ) {
        self._type = _type
        self.id = id
        self.name = name
        self.input = input
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case id
        case name
        case input
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._type = try container.decode(
          Components.Schemas.RequestToolUseBlock._typePayload.self,
          forKey: ._type
        )
        self.id = try container.decode(
          Swift.String.self,
          forKey: .id
        )
        self.name = try container.decode(
          Swift.String.self,
          forKey: .name
        )
        self.input = try container.decode(
          OpenAPIRuntime.OpenAPIObjectContainer.self,
          forKey: .input
        )
        try decoder.ensureNoAdditionalProperties(knownKeys: [
          "type",
          "id",
          "name",
          "input",
        ])
      }
    }
    /// - Remark: Generated from `#/components/schemas/ResponseTextBlock`.
    package struct ResponseTextBlock: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/ResponseTextBlock/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case text = "text"
      }
      /// - Remark: Generated from `#/components/schemas/ResponseTextBlock/type`.
      package var _type: Components.Schemas.ResponseTextBlock._typePayload
      /// - Remark: Generated from `#/components/schemas/ResponseTextBlock/text`.
      package var text: Swift.String
      /// Creates a new `ResponseTextBlock`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - text:
      package init(
        _type: Components.Schemas.ResponseTextBlock._typePayload,
        text: Swift.String
      ) {
        self._type = _type
        self.text = text
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case text
      }
    }
    /// - Remark: Generated from `#/components/schemas/ResponseToolUseBlock`.
    package struct ResponseToolUseBlock: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/ResponseToolUseBlock/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case tool_use = "tool_use"
      }
      /// - Remark: Generated from `#/components/schemas/ResponseToolUseBlock/type`.
      package var _type: Components.Schemas.ResponseToolUseBlock._typePayload
      /// - Remark: Generated from `#/components/schemas/ResponseToolUseBlock/id`.
      package var id: Swift.String
      /// - Remark: Generated from `#/components/schemas/ResponseToolUseBlock/name`.
      package var name: Swift.String
      /// - Remark: Generated from `#/components/schemas/ResponseToolUseBlock/input`.
      package var input: OpenAPIRuntime.OpenAPIObjectContainer
      /// Creates a new `ResponseToolUseBlock`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - id:
      ///   - name:
      ///   - input:
      package init(
        _type: Components.Schemas.ResponseToolUseBlock._typePayload,
        id: Swift.String,
        name: Swift.String,
        input: OpenAPIRuntime.OpenAPIObjectContainer
      ) {
        self._type = _type
        self.id = id
        self.name = name
        self.input = input
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case id
        case name
        case input
      }
    }
    /// - Remark: Generated from `#/components/schemas/Tool`.
    package struct Tool: Codable, Hashable, Sendable {
      /// Description of what this tool does.
      ///
      /// Tool descriptions should be as detailed as possible. The more information that the model has about what the tool is and how to use it, the better it will perform. You can use natural language descriptions to reinforce important aspects of the tool input JSON schema.
      ///
      /// - Remark: Generated from `#/components/schemas/Tool/description`.
      package var description: Swift.String?
      /// Name of the tool.
      ///
      /// This is how the tool will be called by the model and in tool_use blocks.
      ///
      /// - Remark: Generated from `#/components/schemas/Tool/name`.
      package var name: Swift.String
      /// [JSON schema](https://json-schema.org/) for this tool's input.
      ///
      /// This defines the shape of the `input` that your tool accepts and that the model will produce.
      ///
      /// - Remark: Generated from `#/components/schemas/Tool/input_schema`.
      package struct input_schemaPayload: Codable, Hashable, Sendable {
        /// - Remark: Generated from `#/components/schemas/Tool/input_schema/value1`.
        package var value1: Components.Schemas.InputSchema
        /// Creates a new `input_schemaPayload`.
        ///
        /// - Parameters:
        ///   - value1:
        package init(value1: Components.Schemas.InputSchema) {
          self.value1 = value1
        }
        package init(from decoder: any Swift.Decoder) throws {
          self.value1 = try .init(from: decoder)
        }
        package func encode(to encoder: any Swift.Encoder) throws {
          try self.value1.encode(to: encoder)
        }
      }
      /// [JSON schema](https://json-schema.org/) for this tool's input.
      ///
      /// This defines the shape of the `input` that your tool accepts and that the model will produce.
      ///
      /// - Remark: Generated from `#/components/schemas/Tool/input_schema`.
      package var input_schema: Components.Schemas.Tool.input_schemaPayload
      /// Creates a new `Tool`.
      ///
      /// - Parameters:
      ///   - description: Description of what this tool does.
      ///   - name: Name of the tool.
      ///   - input_schema: [JSON schema](https://json-schema.org/) for this tool's input.
      package init(
        description: Swift.String? = nil,
        name: Swift.String,
        input_schema: Components.Schemas.Tool.input_schemaPayload
      ) {
        self.description = description
        self.name = name
        self.input_schema = input_schema
      }
      package enum CodingKeys: String, CodingKey {
        case description
        case name
        case input_schema
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try container.decodeIfPresent(
          Swift.String.self,
          forKey: .description
        )
        self.name = try container.decode(
          Swift.String.self,
          forKey: .name
        )
        self.input_schema = try container.decode(
          Components.Schemas.Tool.input_schemaPayload.self,
          forKey: .input_schema
        )
        try decoder.ensureNoAdditionalProperties(knownKeys: [
          "description",
          "name",
          "input_schema",
        ])
      }
    }
    /// The model will use any available tools.
    ///
    /// - Remark: Generated from `#/components/schemas/ToolChoiceAny`.
    package struct ToolChoiceAny: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/ToolChoiceAny/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case any = "any"
      }
      /// - Remark: Generated from `#/components/schemas/ToolChoiceAny/type`.
      package var _type: Components.Schemas.ToolChoiceAny._typePayload
      /// Whether to disable parallel tool use.
      ///
      /// Defaults to `false`. If set to `true`, the model will output exactly one tool use.
      ///
      /// - Remark: Generated from `#/components/schemas/ToolChoiceAny/disable_parallel_tool_use`.
      package var disable_parallel_tool_use: Swift.Bool?
      /// Creates a new `ToolChoiceAny`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - disable_parallel_tool_use: Whether to disable parallel tool use.
      package init(
        _type: Components.Schemas.ToolChoiceAny._typePayload,
        disable_parallel_tool_use: Swift.Bool? = nil
      ) {
        self._type = _type
        self.disable_parallel_tool_use = disable_parallel_tool_use
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case disable_parallel_tool_use
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._type = try container.decode(
          Components.Schemas.ToolChoiceAny._typePayload.self,
          forKey: ._type
        )
        self.disable_parallel_tool_use = try container.decodeIfPresent(
          Swift.Bool.self,
          forKey: .disable_parallel_tool_use
        )
        try decoder.ensureNoAdditionalProperties(knownKeys: [
          "type",
          "disable_parallel_tool_use",
        ])
      }
    }
    /// The model will automatically decide whether to use tools.
    ///
    /// - Remark: Generated from `#/components/schemas/ToolChoiceAuto`.
    package struct ToolChoiceAuto: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/ToolChoiceAuto/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case auto = "auto"
      }
      /// - Remark: Generated from `#/components/schemas/ToolChoiceAuto/type`.
      package var _type: Components.Schemas.ToolChoiceAuto._typePayload
      /// Whether to disable parallel tool use.
      ///
      /// Defaults to `false`. If set to `true`, the model will output at most one tool use.
      ///
      /// - Remark: Generated from `#/components/schemas/ToolChoiceAuto/disable_parallel_tool_use`.
      package var disable_parallel_tool_use: Swift.Bool?
      /// Creates a new `ToolChoiceAuto`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - disable_parallel_tool_use: Whether to disable parallel tool use.
      package init(
        _type: Components.Schemas.ToolChoiceAuto._typePayload,
        disable_parallel_tool_use: Swift.Bool? = nil
      ) {
        self._type = _type
        self.disable_parallel_tool_use = disable_parallel_tool_use
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case disable_parallel_tool_use
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._type = try container.decode(
          Components.Schemas.ToolChoiceAuto._typePayload.self,
          forKey: ._type
        )
        self.disable_parallel_tool_use = try container.decodeIfPresent(
          Swift.Bool.self,
          forKey: .disable_parallel_tool_use
        )
        try decoder.ensureNoAdditionalProperties(knownKeys: [
          "type",
          "disable_parallel_tool_use",
        ])
      }
    }
    /// The model will use the specified tool with `tool_choice.name`.
    ///
    /// - Remark: Generated from `#/components/schemas/ToolChoiceTool`.
    package struct ToolChoiceTool: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/ToolChoiceTool/type`.
      @frozen package enum _typePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case tool = "tool"
      }
      /// - Remark: Generated from `#/components/schemas/ToolChoiceTool/type`.
      package var _type: Components.Schemas.ToolChoiceTool._typePayload
      /// The name of the tool to use.
      ///
      /// - Remark: Generated from `#/components/schemas/ToolChoiceTool/name`.
      package var name: Swift.String
      /// Whether to disable parallel tool use.
      ///
      /// Defaults to `false`. If set to `true`, the model will output exactly one tool use.
      ///
      /// - Remark: Generated from `#/components/schemas/ToolChoiceTool/disable_parallel_tool_use`.
      package var disable_parallel_tool_use: Swift.Bool?
      /// Creates a new `ToolChoiceTool`.
      ///
      /// - Parameters:
      ///   - _type:
      ///   - name: The name of the tool to use.
      ///   - disable_parallel_tool_use: Whether to disable parallel tool use.
      package init(
        _type: Components.Schemas.ToolChoiceTool._typePayload,
        name: Swift.String,
        disable_parallel_tool_use: Swift.Bool? = nil
      ) {
        self._type = _type
        self.name = name
        self.disable_parallel_tool_use = disable_parallel_tool_use
      }
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
        case name
        case disable_parallel_tool_use
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._type = try container.decode(
          Components.Schemas.ToolChoiceTool._typePayload.self,
          forKey: ._type
        )
        self.name = try container.decode(
          Swift.String.self,
          forKey: .name
        )
        self.disable_parallel_tool_use = try container.decodeIfPresent(
          Swift.Bool.self,
          forKey: .disable_parallel_tool_use
        )
        try decoder.ensureNoAdditionalProperties(knownKeys: [
          "type",
          "name",
          "disable_parallel_tool_use",
        ])
      }
    }
    /// - Remark: Generated from `#/components/schemas/Usage`.
    package struct Usage: Codable, Hashable, Sendable {
      /// The number of input tokens which were used.
      ///
      /// - Remark: Generated from `#/components/schemas/Usage/input_tokens`.
      package var input_tokens: Swift.Int
      /// The number of output tokens which were used.
      ///
      /// - Remark: Generated from `#/components/schemas/Usage/output_tokens`.
      package var output_tokens: Swift.Int
      /// Creates a new `Usage`.
      ///
      /// - Parameters:
      ///   - input_tokens: The number of input tokens which were used.
      ///   - output_tokens: The number of output tokens which were used.
      package init(
        input_tokens: Swift.Int,
        output_tokens: Swift.Int
      ) {
        self.input_tokens = input_tokens
        self.output_tokens = output_tokens
      }
      package enum CodingKeys: String, CodingKey {
        case input_tokens
        case output_tokens
      }
    }
    /// How the model should use the provided tools. The model can use a specific tool, any available tool, or decide by itself.
    ///
    /// - Remark: Generated from `#/components/schemas/ToolChoice`.
    @frozen package enum ToolChoice: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/ToolChoice/ToolChoiceAny`.
      case any(Components.Schemas.ToolChoiceAny)
      /// - Remark: Generated from `#/components/schemas/ToolChoice/ToolChoiceAuto`.
      case auto(Components.Schemas.ToolChoiceAuto)
      /// - Remark: Generated from `#/components/schemas/ToolChoice/ToolChoiceTool`.
      case tool(Components.Schemas.ToolChoiceTool)
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let discriminator = try container.decode(
          Swift.String.self,
          forKey: ._type
        )
        switch discriminator {
        case "any":
          self = .any(try .init(from: decoder))
        case "auto":
          self = .auto(try .init(from: decoder))
        case "tool":
          self = .tool(try .init(from: decoder))
        default:
          throw Swift.DecodingError.unknownOneOfDiscriminator(
            discriminatorKey: CodingKeys._type,
            discriminatorValue: discriminator,
            codingPath: decoder.codingPath
          )
        }
      }
      package func encode(to encoder: any Swift.Encoder) throws {
        switch self {
        case .any(let value):
          try value.encode(to: encoder)
        case .auto(let value):
          try value.encode(to: encoder)
        case .tool(let value):
          try value.encode(to: encoder)
        }
      }
    }
    /// - Remark: Generated from `#/components/schemas/ContentBlock`.
    @frozen package enum ContentBlock: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/ContentBlock/ResponseTextBlock`.
      case text(Components.Schemas.ResponseTextBlock)
      /// - Remark: Generated from `#/components/schemas/ContentBlock/ResponseToolUseBlock`.
      case tool_use(Components.Schemas.ResponseToolUseBlock)
      package enum CodingKeys: String, CodingKey {
        case _type = "type"
      }
      package init(from decoder: any Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let discriminator = try container.decode(
          Swift.String.self,
          forKey: ._type
        )
        switch discriminator {
        case "text":
          self = .text(try .init(from: decoder))
        case "tool_use":
          self = .tool_use(try .init(from: decoder))
        default:
          throw Swift.DecodingError.unknownOneOfDiscriminator(
            discriminatorKey: CodingKeys._type,
            discriminatorValue: discriminator,
            codingPath: decoder.codingPath
          )
        }
      }
      package func encode(to encoder: any Swift.Encoder) throws {
        switch self {
        case .text(let value):
          try value.encode(to: encoder)
        case .tool_use(let value):
          try value.encode(to: encoder)
        }
      }
    }
    /// The model that will complete your prompt.\n\nSee [models](https://docs.anthropic.com/en/docs/models-overview) for additional details and options.
    ///
    /// - Remark: Generated from `#/components/schemas/Model`.
    package struct Model: Codable, Hashable, Sendable {
      /// - Remark: Generated from `#/components/schemas/Model/value1`.
      package var value1: Swift.String?
      /// - Remark: Generated from `#/components/schemas/Model/value2`.
      @frozen package enum Value2Payload: String, Codable, Hashable, Sendable, CaseIterable {
        case claude_hyphen_3_hyphen_5_hyphen_sonnet_hyphen_latest = "claude-3-5-sonnet-latest"
        case claude_hyphen_3_hyphen_5_hyphen_sonnet_hyphen_20241022 = "claude-3-5-sonnet-20241022"
        case claude_hyphen_3_hyphen_5_hyphen_sonnet_hyphen_20240620 = "claude-3-5-sonnet-20240620"
        case claude_hyphen_3_hyphen_opus_hyphen_latest = "claude-3-opus-latest"
        case claude_hyphen_3_hyphen_opus_hyphen_20240229 = "claude-3-opus-20240229"
        case claude_hyphen_3_hyphen_sonnet_hyphen_20240229 = "claude-3-sonnet-20240229"
        case claude_hyphen_3_hyphen_haiku_hyphen_20240307 = "claude-3-haiku-20240307"
        case claude_hyphen_2_period_1 = "claude-2.1"
        case claude_hyphen_2_period_0 = "claude-2.0"
        case claude_hyphen_instant_hyphen_1_period_2 = "claude-instant-1.2"
      }
      /// - Remark: Generated from `#/components/schemas/Model/value2`.
      package var value2: Components.Schemas.Model.Value2Payload?
      /// Creates a new `Model`.
      ///
      /// - Parameters:
      ///   - value1:
      ///   - value2:
      package init(
        value1: Swift.String? = nil,
        value2: Components.Schemas.Model.Value2Payload? = nil
      ) {
        self.value1 = value1
        self.value2 = value2
      }
      package init(from decoder: any Swift.Decoder) throws {
        var errors: [any Swift.Error] = []
        do {
          self.value1 = try decoder.decodeFromSingleValueContainer()
        } catch {
          errors.append(error)
        }
        do {
          self.value2 = try decoder.decodeFromSingleValueContainer()
        } catch {
          errors.append(error)
        }
        try Swift.DecodingError.verifyAtLeastOneSchemaIsNotNil(
          [
            self.value1,
            self.value2,
          ],
          type: Self.self,
          codingPath: decoder.codingPath,
          errors: errors
        )
      }
      package func encode(to encoder: any Swift.Encoder) throws {
        try encoder.encodeFirstNonNilValueToSingleValueContainer([
          self.value1,
          self.value2,
        ])
      }
    }
  }
  /// Types generated from the `#/components/parameters` section of the OpenAPI document.
  package enum Parameters {}
  /// Types generated from the `#/components/requestBodies` section of the OpenAPI document.
  package enum RequestBodies {}
  /// Types generated from the `#/components/responses` section of the OpenAPI document.
  package enum Responses {}
  /// Types generated from the `#/components/headers` section of the OpenAPI document.
  package enum Headers {}
}

/// API operations, with input and output types, generated from `#/paths` in the OpenAPI document.
package enum Operations {
  /// Create a Message
  ///
  /// Send a structured list of input messages with text and/or image content, and the model will generate the next message in the conversation.
  ///
  /// The Messages API can be used for either single queries or stateless multi-turn conversations.
  ///
  /// - Remark: HTTP `POST /v1/messages`.
  /// - Remark: Generated from `#/paths//v1/messages/post(messages_post)`.
  package enum messages_post {
    package static let id: Swift.String = "messages_post"
    package struct Input: Sendable, Hashable {
      /// - Remark: Generated from `#/paths/v1/messages/POST/header`.
      package struct Headers: Sendable, Hashable {
        /// The version of the Anthropic API you want to use.
        ///
        /// Read more about versioning and our version history [here](https://docs.anthropic.com/en/api/versioning).
        ///
        /// - Remark: Generated from `#/paths/v1/messages/POST/header/anthropic-version`.
        package var anthropic_hyphen_version: Swift.String?
        /// Your unique API key for authentication.
        ///
        /// This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
        ///
        /// - Remark: Generated from `#/paths/v1/messages/POST/header/x-api-key`.
        package var x_hyphen_api_hyphen_key: Swift.String?
        package var accept:
          [OpenAPIRuntime.AcceptHeaderContentType<Operations.messages_post.AcceptableContentType>]
        /// Creates a new `Headers`.
        ///
        /// - Parameters:
        ///   - anthropic_hyphen_version: The version of the Anthropic API you want to use.
        ///   - x_hyphen_api_hyphen_key: Your unique API key for authentication.
        ///   - accept:
        package init(
          anthropic_hyphen_version: Swift.String? = nil,
          x_hyphen_api_hyphen_key: Swift.String? = nil,
          accept: [OpenAPIRuntime.AcceptHeaderContentType<
            Operations.messages_post.AcceptableContentType
          >] = .defaultValues()
        ) {
          self.anthropic_hyphen_version = anthropic_hyphen_version
          self.x_hyphen_api_hyphen_key = x_hyphen_api_hyphen_key
          self.accept = accept
        }
      }
      package var headers: Operations.messages_post.Input.Headers
      /// - Remark: Generated from `#/paths/v1/messages/POST/requestBody`.
      @frozen package enum Body: Sendable, Hashable {
        /// - Remark: Generated from `#/paths/v1/messages/POST/requestBody/content/application\/json`.
        case json(Components.Schemas.CreateMessageParams)
      }
      package var body: Operations.messages_post.Input.Body
      /// Creates a new `Input`.
      ///
      /// - Parameters:
      ///   - headers:
      ///   - body:
      package init(
        headers: Operations.messages_post.Input.Headers = .init(),
        body: Operations.messages_post.Input.Body
      ) {
        self.headers = headers
        self.body = body
      }
    }
    @frozen package enum Output: Sendable, Hashable {
      package struct Ok: Sendable, Hashable {
        /// - Remark: Generated from `#/paths/v1/messages/POST/responses/200/content`.
        @frozen package enum Body: Sendable, Hashable {
          /// - Remark: Generated from `#/paths/v1/messages/POST/responses/200/content/application\/json`.
          case json(Components.Schemas.Message)
          /// The associated value of the enum case if `self` is `.json`.
          ///
          /// - Throws: An error if `self` is not `.json`.
          /// - SeeAlso: `.json`.
          package var json: Components.Schemas.Message {
            get throws {
              switch self {
              case .json(let body):
                return body
              }
            }
          }
        }
        /// Received HTTP response body
        package var body: Operations.messages_post.Output.Ok.Body
        /// Creates a new `Ok`.
        ///
        /// - Parameters:
        ///   - body: Received HTTP response body
        package init(body: Operations.messages_post.Output.Ok.Body) {
          self.body = body
        }
      }
      /// Message object.
      ///
      /// - Remark: Generated from `#/paths//v1/messages/post(messages_post)/responses/200`.
      ///
      /// HTTP response code: `200 ok`.
      case ok(Operations.messages_post.Output.Ok)
      /// The associated value of the enum case if `self` is `.ok`.
      ///
      /// - Throws: An error if `self` is not `.ok`.
      /// - SeeAlso: `.ok`.
      package var ok: Operations.messages_post.Output.Ok {
        get throws {
          switch self {
          case .ok(let response):
            return response
          default:
            try throwUnexpectedResponseStatus(
              expectedStatus: "ok",
              response: self
            )
          }
        }
      }
      package struct ClientError: Sendable, Hashable {
        /// - Remark: Generated from `#/paths/v1/messages/POST/responses/4XX/content`.
        @frozen package enum Body: Sendable, Hashable {
          /// - Remark: Generated from `#/paths/v1/messages/POST/responses/4XX/content/application\/json`.
          case json(Components.Schemas.ErrorResponse)
          /// The associated value of the enum case if `self` is `.json`.
          ///
          /// - Throws: An error if `self` is not `.json`.
          /// - SeeAlso: `.json`.
          package var json: Components.Schemas.ErrorResponse {
            get throws {
              switch self {
              case .json(let body):
                return body
              }
            }
          }
        }
        /// Received HTTP response body
        package var body: Operations.messages_post.Output.ClientError.Body
        /// Creates a new `ClientError`.
        ///
        /// - Parameters:
        ///   - body: Received HTTP response body
        package init(body: Operations.messages_post.Output.ClientError.Body) {
          self.body = body
        }
      }
      /// Error response.
      ///
      /// See our [errors documentation](https://docs.anthropic.com/en/api/errors) for more details.
      ///
      /// - Remark: Generated from `#/paths//v1/messages/post(messages_post)/responses/4XX`.
      ///
      /// HTTP response code: `400...499 clientError`.
      case clientError(statusCode: Swift.Int, Operations.messages_post.Output.ClientError)
      /// The associated value of the enum case if `self` is `.clientError`.
      ///
      /// - Throws: An error if `self` is not `.clientError`.
      /// - SeeAlso: `.clientError`.
      package var clientError: Operations.messages_post.Output.ClientError {
        get throws {
          switch self {
          case .clientError(_, let response):
            return response
          default:
            try throwUnexpectedResponseStatus(
              expectedStatus: "clientError",
              response: self
            )
          }
        }
      }
      /// Undocumented response.
      ///
      /// A response with a code that is not documented in the OpenAPI document.
      case undocumented(statusCode: Swift.Int, OpenAPIRuntime.UndocumentedPayload)
    }
    @frozen package enum AcceptableContentType: AcceptableProtocol {
      case json
      case other(Swift.String)
      package init?(rawValue: Swift.String) {
        switch rawValue.lowercased() {
        case "application/json":
          self = .json
        default:
          self = .other(rawValue)
        }
      }
      package var rawValue: Swift.String {
        switch self {
        case .other(let string):
          return string
        case .json:
          return "application/json"
        }
      }
      package static var allCases: [Self] {
        [
          .json
        ]
      }
    }
  }
}
