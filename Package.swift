// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "HubClient",
  platforms: [.iOS(.v15), .macCatalyst(.v15), .tvOS(.v15), .macOS(.v12), .watchOS(.v8), .visionOS(.v1)],
  products: [.library(name: "HubClient", targets: ["HubClient"])],
  dependencies: [.package(url: "https://github.com/v57/ChannelSwift.git", branch: "main")],
  targets: [
    .target(name: "HubClient", dependencies: [.product(name: "Channel", package: "ChannelSwift")]),
  ]
)
