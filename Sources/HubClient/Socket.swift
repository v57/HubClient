//
//  File.swift
//  WebSocket
//
//  Created by Dmitry Kozlov on 8/2/25.
//

import Foundation
import Combine

@globalActor
public actor WebActor: GlobalActor {
  public static let shared = WebActor()
}

@WebActor
public class WebSocketCore {
  @Published var connection: WebSocketTask?
  enum ResponseEvent {
    case waiting(@WebActor (Response) -> ()), received(Response)
  }
  var responses = [UInt32: ResponseEvent]()
  let request: URLRequest
  var ids = MessageId()
  public init(request: URLRequest) {
    self.request = request
  }
}


