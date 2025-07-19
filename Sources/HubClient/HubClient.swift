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
  public nonisolated static var local: URL { URL(string: "ws://127.0.0.1:1997")! }
  public var isConnected: Published<Bool>.Publisher {
    sender.ws.$isConnected
  }
  public var debugNetwork: Bool {
    get { sender.ws.debug }
    set { sender.ws.debug = newValue }
  }
  let channel: Channel<Void>
  let service: HubService
  private var sender: ClientSender<Void>!
  public init(_ url: URL = HubClient.local, keyChain: KeyChain? = nil) {
    channel = Channel()
    service = HubService(channel: channel)
    if let keyChain {
      sender = nil
      sender = channel.connect(url, options: ClientOptions(headers: {
        let key = keyChain.publicKey()
        let time = "\(Int(Date().timeIntervalSince1970 + 60))"
        let sign = keyChain.sign(text: time)
        return ["auth": "key.\(key).\(sign).\(time)"]
      }, onConnect: { [weak self] sender in
        guard let self else { return }
        let update = await HubService.Update(add: service.api, addApps: service.apps)
        if !update.isEmpty {
          try await sender.send("hub/service/update", update)
        }
      }))
    } else {
      sender = channel.connect(url)
    }
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
  public func values<Output: Decodable>(_ path: String) -> Values<Void, EmptyCodable, Output> {
    sender.values(path)
  }
  public func values(_ path: String) -> Values<Void, EmptyCodable, EmptyCodable> {
    sender.values(path)
  }
  public func values<Body: Encodable>(_ path: String, _ body: Body?) -> Values<Void, Body, EmptyCodable> {
    sender.values(path, body)
  }
  public func values<Body: Encodable, Output: Decodable>(_ path: String, _ body: Body?) -> Values<Void, Body, Output> {
    sender.values(path, body)
  }
  public func stop() {
    sender.stop()
  }
}

