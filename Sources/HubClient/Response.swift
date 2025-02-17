//
//  File.swift
//  WebSocket
//
//  Created by Dmitry Kozlov on 8/2/25.
//

import Foundation

extension WebSocketCore {
  func received(string: String) {
    do {
      guard let data = string.data(using: .utf8) else { return }
      let response = try JSONDecoder.iso8601.decode(Response.self, from: data)
      received(response: response)
    } catch { }
  }
  func received(response: Response) {
    if let event = responses[response.id], case .waiting(let c) = event {
      responses[response.id] = nil
      c(response)
    } else {
      responses[response.id] = .received(response)
    }
  }
  func onEvent(key: UInt32) async -> Response {
    await withUnsafeContinuation { c in
      if let value = responses[key] {
        switch value {
        case .waiting(let old):
          responses[key] = .waiting({ value in
            old(value)
            c.resume(returning: value)
          })
        case .received(let value):
          responses[key] = nil
          c.resume(returning: value)
        }
      } else {
        responses[key] = .waiting({ value in
          c.resume(returning: value)
        })
      }
    }
  }
}
