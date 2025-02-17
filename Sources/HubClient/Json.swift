//
//  File.swift
//  WebSocket
//
//  Created by Dmitry Kozlov on 8/2/25.
//

import Foundation

extension JSONDecoder {
  static let formatter = Date.ISO8601FormatStyle().dateSeparator(.dash).time(includingFractionalSeconds: true)
  struct InvalidDateFormat: Error { }
  static let iso8601: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom {
      let string = try $0.singleValueContainer().decode(String.self)
      return try Date.init(string, strategy: formatter)
    }
    return decoder
  }()
}
extension JSONEncoder {
  static let iso8601: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .custom { date, encoder in
      try JSONDecoder.formatter.format(date).encode(to: encoder)
    }
    return encoder
  }()
}
