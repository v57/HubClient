//
//  File.swift
//  HubClient
//
//  Created by Linux on 19.07.25.
//

import Foundation

struct App: Sendable {
  var header: AppHeader
  var body: [Element]
  var data: [String: String]
  init(header: AppHeader, body: [Element], data: [String: String]) {
    self.header = header
    self.body = body
    self.data = data
  }
}

extension HubService {
  func app(_ app: App) -> Self {
    apps.append(app.header)
    return stream(app.header.path) { continuation in
      continuation.yield(AppInterface(header: app.header, body: app.body))
    }
  }
}

struct AppInterface: Codable {
  var header: AppHeader?
  var body: [Element]?
  enum CodingKeys: CodingKey {
    case header, body
  }
  
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    header = try? container.decodeIfPresent(.header)
    body = try? container.decodeLossy(.body)
  }
  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(header, forKey: .header)
    try container.encodeIfPresent(body, forKey: .body)
  }
  init(header: AppHeader, body: [Element]) {
    self.header = header
    self.body = body
  }
  init() {
    
  }
}

enum ElementType: String, Codable {
  case text, textField, button, list, picker, cell, files, fileOperation
}

protocol ElementProtocol {
  var type: ElementType { get }
  var id: String { get }
}

enum Element: Identifiable, Codable, Sendable {
  var id: String {
    switch self {
    case .text(let a): a.id
    case .textField(let a): a.id
    case .button(let a): a.id
    case .list(let a): a.id
    case .picker(let a): a.id
    case .cell(let a): a.id
    case .files(let a): a.id
    case .fileOperation(let a): a.id
    }
  }
  case text(Text)
  case textField(TextField)
  case button(Button)
  case list(List)
  case picker(Picker)
  case cell(Cell)
  case files(Files)
  case fileOperation(FileOperation)
  enum CodingKeys: CodingKey {
    case type
  }
  
  init(from decoder: any Decoder) throws {
    do {
      let value: String = try decoder.decode()
      self = .text(Text(value: value))
    } catch {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let type: ElementType = try container.decode(.type)
      switch type {
      case .text:
        self = try .text(Text(from: decoder))
      case .textField:
        self = try .textField(TextField(from: decoder))
      case .button:
        self = try .button(Button(from: decoder))
      case .list:
        self = try .list(List(from: decoder))
      case .picker:
        self = try .picker(Picker(from: decoder))
      case .cell:
        self = try .cell(Cell(from: decoder))
      case .files:
        self = try .files(Files(from: decoder))
      case .fileOperation:
        self = try .fileOperation(FileOperation(from: decoder))
      }
    }
  }
  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .text(let text):
      try container.encode(ElementType.text, forKey: .type)
      try text.encode(to: encoder)
    case .textField(let textField):
      try container.encode(ElementType.textField, forKey: .type)
      try textField.encode(to: encoder)
    case .button(let button):
      try container.encode(ElementType.button, forKey: .type)
      try button.encode(to: encoder)
    case .list(let list):
      try container.encode(ElementType.list, forKey: .type)
      try list.encode(to: encoder)
    case .picker(let picker):
      try container.encode(ElementType.picker, forKey: .type)
      try picker.encode(to: encoder)
    case .cell(let cell):
      try container.encode(ElementType.cell, forKey: .type)
      try cell.encode(to: encoder)
    case .files(let files):
      try container.encode(ElementType.files, forKey: .type)
      try files.encode(to: encoder)
    case .fileOperation(let fileOperation):
      try container.encode(ElementType.fileOperation, forKey: .type)
      try fileOperation.encode(to: encoder)
    }
  }
  struct Text: ElementProtocol, Identifiable, Codable, Sendable {
    var type: ElementType { .text }
    let id = UUID().uuidString
    let value: String
    let secondary: Bool
    enum CodingKeys: CodingKey {
      case value
      case secondary
    }
    init(value: String) {
      self.value = value
      self.secondary = false
    }
    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.value = try container.decode(.value)
      self.secondary = container.decodeIfPresent(.secondary, false)
    }
  }
  struct TextField: ElementProtocol, Identifiable, Codable, Sendable {
    var type: ElementType { .textField }
    let id = UUID().uuidString
    let value: String
    let placeholder: String
    let action: Action?
    enum CodingKeys: CodingKey {
      case value, placeholder, action
    }
    
    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.value = try container.decode(.value)
      self.placeholder = container.decodeIfPresent(.placeholder, "")
      self.action = try container.decode(.action)
    }
  }
  struct Button: ElementProtocol, Identifiable, Codable, Sendable {
    var type: ElementType { .button }
    let id = UUID().uuidString
    let title: String
    let action: Action
    enum CodingKeys: CodingKey {
      case title
      case action
    }
    
    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      title = try container.decode(.title)
      action = try container.decode(.action)
    }
  }
  final class List: ElementProtocol, Identifiable, Codable, Sendable {
    var type: ElementType { .list }
    let id = UUID().uuidString
    let data: String
    let elements: Element
    enum CodingKeys: CodingKey {
      case data, elements
    }
    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      data = try container.decode(.data)
      elements = try container.decode(.elements)
    }
  }
  struct Picker: ElementProtocol, Identifiable, Codable, Sendable {
    var type: ElementType { .list }
    let id = UUID().uuidString
    let options: [String]
    let selected: String
    enum CodingKeys: CodingKey {
      case options, selected
    }
    
    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      options = try container.decode(.options)
      selected = try container.decode(.selected)
    }
  }
  final class Cell: ElementProtocol, Identifiable, Codable, Sendable {
    var type: ElementType { .cell }
    let id = UUID().uuidString
    let title: Element?
    let subtitle: Element?
    enum CodingKeys: CodingKey {
      case title, subtitle
    }
    
    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.title = try container.decodeIfPresent(.title)
      self.subtitle = try container.decodeIfPresent(.subtitle)
    }
  }
  final class Files: ElementProtocol, Identifiable, Codable, Sendable {
    var type: ElementType { .files }
    let id = UUID().uuidString
    let title: Element?
    let value: String
    let action: Action
    enum CodingKeys: CodingKey {
      case title, value, action
    }
    
    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.title = try container.decodeIfPresent(.title)
      self.value = try container.decode(.value)
      self.action = try container.decode(.action)
    }
  }
  final class FileOperation: ElementProtocol, Identifiable, Codable, Sendable {
    var type: ElementType { .fileOperation }
    let id = UUID().uuidString
    let title: Element?
    let value: String
    let action: Action
    enum CodingKeys: CodingKey {
      case title, value, action
    }
    
    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.title = try container.decodeIfPresent(.title)
      self.value = try container.decode(.value)
      self.action = try container.decode(.action)
    }
  }
  struct Action: Codable, Sendable {
    var path: String
    var body: ActionBody
    var output: ActionBody?
    enum CodingKeys: CodingKey {
      case path, body, output
    }
    
    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.path = try container.decode(.path)
      self.body = try container.decode(.body)
      self.output = try container.decodeIfPresent(.output)
    }
  }
  enum ActionBody: Codable, Sendable {
    case void
    case single(String)
    case multiple([String: String])
    enum CodingKeys: CodingKey {
      case single, multiple
    }
    
    init(from decoder: any Decoder) throws {
      do {
        do {
          self = try .single(decoder.decode())
        } catch {
          self = try .multiple(decoder.decode())
        }
      } catch {
        self = .void
      }
    }
    
    func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      switch self {
      case .single(let string):
        try container.encode(string)
      case .multiple(let dictionary):
        try container.encode(dictionary)
      case .void: break
      }
    }
  }
}

extension Dictionary {
  mutating func insert(contentsOf dictionary: Dictionary) {
    dictionary.forEach { key, value in
      self[key] = value
    }
  }
}
