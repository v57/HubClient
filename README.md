<h1>
  <img alt="Containerization logo" src="./icon.png" width="70" valign="middle">
  &nbsp;Hub Service
</h1>

> Made for [Hub](https://hub.v57.dev)

Hub Service allows you to connect to Hub, use it's api or share your own. 

### Features
- Connect to Hub Lite and Hub Pro
- Call api, stream updates
- Add your own `async` and `AsyncIterator` api to Hub
- Display and interract with apps
- Post your own apps


### Getting started
```swift
// Create hub connection
let url: URL // "wss://example.com/hub"
let client = HubClient(url, keyChain: KeyChain(keyChain: "com.example.YourApp"), connect: true)

// Host your service
client.service.post("myservice/x2") { (value: Int) in
  return value * 2
}

// Call Hub api
let availableApi: Set<String> = try await client.send("hub/api")

// Test your service
print(try await client.send("myservice/x2", 2) == 4)
```
