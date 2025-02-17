//
//  File.swift
//  WebSocket
//
//  Created by Dmitry Kozlov on 8/2/25.
//

import Foundation

public typealias WebSocketTask = URLSessionWebSocketTask

extension WebSocketTask {
  static func connect(request: URLRequest) async throws -> WebSocketTask {
    try await URLSession.shared.webSocket(with: request)
  }
}

extension URLSession {
  final class WebSocketDelegate: NSObject, URLSessionWebSocketDelegate {
    let completion: @MainActor @Sendable (Result<URLSessionWebSocketTask, Error>) -> ()
    init(completion: @MainActor @Sendable @escaping (Result<URLSessionWebSocketTask, Error>) -> ()) {
      self.completion = completion
    }
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
      complete(.success(webSocketTask))
    }
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
      complete(.failure(CancellationError()))
    }
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
      if let error {
        complete(.failure(error))
      } else {
        complete(.failure(CancellationError()))
      }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
      if let error {
        complete(.failure(error))
      } else {
        complete(.failure(CancellationError()))
      }
    }
    func complete(_ result: Result<URLSessionWebSocketTask, Error>) {
      Task { @MainActor in
        completion(result)
      }
    }
  }
  func webSocket(with request: URLRequest) async throws -> URLSessionWebSocketTask {
    let task = webSocketTask(with: request)
    return try await withTaskCancellationHandler(operation: {
      try await withCheckedThrowingContinuation { continuation in
        var sent = false
        task.delegate = WebSocketDelegate {
          guard !sent else { return }
          sent = true
          continuation.resume(with: $0)
        }
        task.resume()
      }
    }, onCancel: {
      task.cancel()
    })
  }
}
