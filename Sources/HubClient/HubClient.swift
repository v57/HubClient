//
//  File.swift
//  WebSocket
//
//  Created by Dmitry Kozlov on 17/2/25.
//

import Foundation

@MainActor
public class HubClient {
  @WebActor
  var ws: WebSocketCore?
  var connect: Task<Void, Error>?
  let request: URLRequest
  public init(port: Int = 1997) {
    request = URLRequest(url: URL(string: "ws://127.0.0.1:\(port)")!)
  }
  @WebActor
  public func test() {
    
  }
  @WebActor
  public func send<Output: Decodable>(_ path: String) async throws -> Output {
    try await send(path, nil as Optional<Int>)
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
}
