//
//  File.swift
//  HubClient
//
//  Created by Linux on 19.07.25.
//

import Foundation
import Channel

@MainActor
public class HubService {
  let channel: Channel<Void>
  var apps = [AppHeader]()
  var api: [String] {
    Array(Set(channel.postApi.keys).union(channel.streamApi.keys))
  }
  init(channel: Channel<Void>) {
    self.channel = channel
  }
  public func post<Input: Decodable, Output: Encodable & Sendable>(_ path: String, request: @escaping (@Sendable (Input) async throws -> Output)) -> Self {
    _ = channel.post(path, request: request)
    return self
  }
  public func post<Input: Decodable>(_ path: String, request: @escaping (@Sendable (Input) async throws -> Void)) -> Self {
    _ = channel.post(path, request: request)
    return self
  }
  public func post<Output: Encodable & Sendable>(_ path: String, request: @escaping (@Sendable () async throws -> Output)) -> Self {
    _ = channel.post(path, request: request)
    return self
  }
  public func post(_ path: String, request: @escaping (@Sendable () async throws -> Void)) -> Self {
    _ = channel.post(path, request: request)
    return self
  }
  public func stream<Input: Decodable & Sendable>(_ path: String, request: @escaping @Sendable (Input, AsyncThrowingStream<Encodable & Sendable, Error>.Continuation) async throws -> Void) -> Self {
    _ = channel.stream(path, request: request)
    return self
  }
  public func stream(_ path: String, request: @escaping @Sendable (AsyncThrowingStream<Encodable & Sendable, Error>.Continuation) async throws -> Void) -> Self {
    _ = channel.stream(path, request: request)
    return self
  }
  struct Update: Encodable {
    var add: [String]
    var addApps: [AppHeader]
    var isEmpty: Bool { add.isEmpty && addApps.isEmpty }
  }
}

struct AppHeader: Codable, Sendable {
  var type: AppType
  var name: String
  var path: String
  enum AppType: String, Codable {
    case app
  }
}

