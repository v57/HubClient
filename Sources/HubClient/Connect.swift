//
//  File.swift
//  WebSocket
//
//  Created by Dmitry Kozlov on 8/2/25.
//

import Foundation

extension WebSocketCore {
  public func connect() async throws {
    var attempts = Attempts()
    while true {
      do {
        try await attempts.sleep()
        let ws = try await WebSocketTask.connect(request: request)
        connection = ws
        attempts.success()
        do {
          while true {
            let message = try await ws.receive()
            switch message {
            case .data: break
            case .string(let string):
              received(string: string)
            @unknown default: break
            }
          }
        } catch {
          connection = nil
        }
      } catch {
        attempts.failed()
        connection = nil
      }
    }
  }
  
  @discardableResult
  func onConnect() async throws -> WebSocketTask {
    for await values in $connection.values {
      if let connection = values {
        return connection
      }
    }
    throw CancellationError()
  }
}

private struct Attempts {
  var count = 0
  mutating func success() {
    count = 0
  }
  mutating func failed() {
    count += 1
  }
  func sleep() async throws {
    try await Task.sleep(nanoseconds: UInt64(count) * 1_000_000_000)
  }
}
