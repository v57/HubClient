//
//  File.swift
//  WebSocket
//
//  Created by Dmitry Kozlov on 17/2/25.
//

import Foundation
import Combine

@MainActor
public class HubClient {
  @WebActor
  @Published var ws: WebSocketCore?
  var connect: Task<Void, Error>?
  let request: URLRequest
  @Published
  @WebActor
  public var isConnected = false
  @WebActor
  private var connectedTask: AnyCancellable?
  public init(port: Int = 1997) {
    request = URLRequest(url: URL(string: "ws://127.0.0.1:\(port)")!)
  }
  @WebActor
  public func test() {
    
  }
  @WebActor
  public func send<Output: Decodable>(_ path: String) async throws -> Output {
    try await send(path, Empty())
  }
  @WebActor
  public func send(_ path: String) async throws {
    _ = try await send(path, Empty()) as Empty?
  }
  @WebActor
  public func send<Body: Encodable>(_ path: String, _ body: Body?) async throws {
    if let ws {
      _ = try await ws.send(path, body) as Int?
    } else {
      _ = try await createWebsocket().send(path, body) as Empty?
    }
  }
  @WebActor
  public func send<Body: Encodable, Output: Decodable>(_ path: String, _ body: Body?) async throws -> Output {
    if let ws {
      return try await ws.send(path, body)
    } else {
      return try await createWebsocket().send(path, body)
    }
  }
  @WebActor
  private func createWebsocket() async -> WebSocketCore {
    let ws = WebSocketCore(request: request)
    connectedTask = ws.$connection.map { $0 != nil }.sink { [weak self] isConnected in
      Task {
        self?.isConnected = isConnected
      }
    }
    self.ws = ws
    await MainActor.run {
      connect = Task {
        try await ws.connect()
      }
    }
    return ws
  }
  deinit {
    connect?.cancel()
  }
  struct Empty: Codable {
    init() { }
    init(from decoder: any Decoder) throws {
    }
    func encode(to encoder: any Encoder) throws {
      
    }
  }
}
