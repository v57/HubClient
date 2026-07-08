//
//  File.swift
//  HubService
//
//  Created by Dmitry Kozlov on 30/4/25.
//

import Foundation
#if canImport(Crypto)
import Crypto
#else
import CryptoKit
#endif

public struct KeyChain: Sendable {
  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
  public static var test: KeyChain { .documents }
  #else
  public static var test: KeyChain { .home }
  #endif
  @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
  public static var home: KeyChain { KeyChain(.home) }
  public static var documents: KeyChain { KeyChain(.documents) }
  public static func file(_ url: URL) -> KeyChain {
    KeyChain(.file(url))
  }
  public static func keychain(_ tag: String) -> KeyChain {
    KeyChain(.keychain(tag))
  }
  public enum Location {
    case file(URL)
    static var documents: Location {
      .file(FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("hub.key"))
    }
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    static var home: Location {
      .file(URL.homeDirectory.appendingPathComponent("hub.key"))
    }
    case none
#if canImport(Security)
    case keychain(String)
#endif
    func load() -> Data? {
      switch self {
      case .file(let url):
        return try? Data(contentsOf: url)
      case .none: return nil
#if canImport(Security)
      case .keychain(let tag):
        let query = [
          kSecClass: kSecClassGenericPassword,
          kSecAttrService: tag,
          kSecReturnData: kCFBooleanTrue!,
          kSecMatchLimit: kSecMatchLimitOne
        ] as [CFString: Any] as CFDictionary
        var value: AnyObject?
        let status = SecItemCopyMatching(query, &value)
        guard status == errSecSuccess else { return nil }
        return value as? Data
#endif
      }
    }
    func save(_ data: Data) {
      switch self {
      case .file(let url):
        try? data.write(to: url, options: .atomic)
      case .none: break
#if canImport(Security)
      case .keychain(let tag):
        let query = [
          kSecClass: kSecClassGenericPassword,
          kSecAttrService: tag,
          kSecValueData: data
        ] as [CFString: Any] as CFDictionary
        SecItemDelete(query)
        SecItemAdd(query, nil)
#endif
      }
    }
  }
  
  private let privateKey: Curve25519.Signing.PrivateKey
  public init(_ location: Location) {
    if let data = location.load(), let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: data) {
      self.privateKey = key
    } else {
      let key = Curve25519.Signing.PrivateKey()
      location.save(key.rawRepresentation)
      self.privateKey = key
    }
  }
  func sign(text: String) -> String {
    let data = Data(text.utf8)
    let signature = try! privateKey.signature(for: data)
    return signature.base64EncodedString()
  }

  public func publicKey() -> String {
    // ed25519 prefix
    let prefix = Data([0x30, 0x2a, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x03, 0x21, 0x00])
    return (prefix + privateKey.publicKey.rawRepresentation).base64EncodedString()
  }
}
