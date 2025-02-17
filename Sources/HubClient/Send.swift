//
//  File.swift
//  WebSocket
//
//  Created by Dmitry Kozlov on 8/2/25.
//

import Foundation

extension WebSocketCore {
  struct Request<Body: Encodable>: Encodable {
    let id: UInt32
    let path: String
    let body: Body?
  }
  struct Response: Decodable, @unchecked Sendable {
    struct ResponseError: Error {
      let message: String
    }
    let id: UInt32
    let result: Result<KeyedDecodingContainer<CodingKeys>, ResponseError>
    enum CodingKeys: CodingKey {
      case id, body, error
    }
    
    init(from decoder: any Decoder) throws {
      let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try container.decode(UInt32.self, forKey: .id)
      if let error = try container.decodeIfPresent(String.self, forKey: .error) {
        result = .failure(ResponseError(message: error))
      } else {
        result = .success(container)
      }
    }
    func body<T: Decodable>() throws -> T {
      switch result {
      case .success(let success):
        try success.decode(T.self, forKey: .body)
      case .failure(let failure):
        throw failure
      }
    }
  }
  
  struct MessageId {
    var id: UInt32 = 0
    mutating func next() -> UInt32 {
      id &+= 1
      return id
    }
  }
  
  public func send<Output: Decodable>(_ path: String) async throws -> Output {
    try await send(path, nil as Optional<Int>)
  }
  public func send<Body: Encodable, Output: Decodable>(_ path: String, _ body: Body?) async throws -> Output {
    let id = ids.next()
    let request = Request(id: id, path: path, body: body)
    let json = try JSONEncoder.iso8601.encode(request)
    let string = String(data: json, encoding: .utf8)!
    try await send(.string(string))
    return try await onEvent(key: id).body()
  }
  
  func send(_ message: URLSessionWebSocketTask.Message) async throws {
    while !Task.isCancelled {
      do {
        let ws = try await onConnect()
        try await ws.send(message)
        return
      } catch is CancellationError {
        return
      } catch { }
    }
    throw CancellationError()
  }
}
