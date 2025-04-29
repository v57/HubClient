//
//  File.swift
//  HubClient
//
//  Created by Dmitry Kozlov on 30/4/25.
//

import Foundation
import CryptoKit

public struct KeyChain {
  private static let fileURL: URL = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("ed25519.key")
  
  private let privateKey: Curve25519.Signing.PrivateKey
  public init(keyChain: String? = nil) {
    if let keyChain,
       let keyData = KeyChain.fromKeychain(tag: keyChain),
       let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: keyData) {
      self.privateKey = key
    } else if let keyData = KeyChain.fromFile(),
              let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: keyData) {
      self.privateKey = key
    } else {
      let key = Curve25519.Signing.PrivateKey()
      let raw = key.rawRepresentation
      if let keyChain, KeyChain.storeInKeyChain(data: raw, tag: keyChain) {
        self.privateKey = key
      } else {
        KeyChain.storeInFile(data: raw)
        self.privateKey = key
      }
    }
  }
  func sign(text: String) -> String {
    let data = Data(text.utf8)
    let signature = try! privateKey.signature(for: data)
    return signature.base64EncodedString()
  }

  func publicKey() -> String {
    // ed25519 prefix
    let prefix = Data([0x30, 0x2a, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x03, 0x21, 0x00])
    return (prefix + privateKey.publicKey.rawRepresentation).base64EncodedString()
  }

  // MARK: - Storage Helpers

  private static func fromKeychain(tag: String) -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: tag,
      kSecReturnData as String: kCFBooleanTrue!,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
    
    guard status == errSecSuccess, let data = dataTypeRef as? Data else {
      return nil
    }
    
    return data
  }

  private static func fromFile() -> Data? {
    try? Data(contentsOf: fileURL)
  }

  private static func storeInKeyChain(data: Data, tag: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: tag,
      kSecValueData as String: data
    ]
    SecItemDelete(query as CFDictionary)
    return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
  }

  private static func storeInFile(data: Data) {
    do {
      try data.write(to: fileURL, options: .atomic)
    } catch {
      print("Failed to write Ed25519 key to file: \(error)")
    }
  }
}
