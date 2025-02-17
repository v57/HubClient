// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "HubClient",
  platforms: [.iOS(.v15), .macCatalyst(.v15), .tvOS(.v15), .macOS(.v12), .watchOS(.v8), .visionOS(.v1)],
  products: [.library(name: "HubClient", targets: ["HubClient"])],
  targets: [.target(name: "HubClient")]
)
