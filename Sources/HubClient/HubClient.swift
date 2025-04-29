//
//  File.swift
//  WebSocket
//
//  Created by Dmitry Kozlov on 17/2/25.
//

import Foundation
import Combine
import Channel

@MainActor
public class HubClient {
  @Published
  public var isConnected = false
  let channel: Channel<Void>
  let sender: ClientSender<Void>
  public init(_ port: Int = 1997) {
    channel = Channel()
    sender = channel.connect(port)
  }
  public func send<Output: Decodable>(_ path: String) async throws -> Output {
    try await sender.send(path)
  }
  public func send(_ path: String) async throws {
    try await sender.send(path)
  }
  public func send<Body: Encodable>(_ path: String, _ body: Body?) async throws {
    try await sender.send(path, body)
  }
  public func send<Body: Encodable, Output: Decodable>(_ path: String, _ body: Body?) async throws -> Output {
    try await sender.send(path, body)
  }
}
