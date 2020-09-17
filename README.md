# ACActionCable
[ACActionCable](https://github.com/High5Apps/ACActionCable) is a Swift 5 client for [Ruby on Rails](https://rubyonrails.org/) 6's [Action Cable](https://guides.rubyonrails.org/action_cable_overview.html) WebSocket server. It is a hard fork of [Action-Cable-Swift](https://github.com/nerzh/Action-Cable-Swift). It aims to be well-tested, dependency-free, and easy to use.

## Installation
### CocoaPods
If your project doesn't use [CocoaPods](https://cocoapods.org/) yet, [follow this guide](https://guides.cocoapods.org/using/using-cocoapods.html).

Add the following line to your `Podfile`:
```ruby
pod 'ACActionCable', '~> 1.0.0'
```

## Usage

### Implement ACWebSocketProtocol
You can use ACActionCable with any WebSocket library you'd like. Just create a class that implements [`ACWebSocketProtocol`](https://github.com/High5Apps/ACActionCable/blob/master/Sources/ACActionCable/ACWebSocketProtocol.swift). If you use [Starscream](https://github.com/daltoniam/Starscream), you can just copy [`ACStarscreamWebSocket`](https://github.com/High5Apps/ACActionCable/blob/master/Examples/ACStarscreamWebSocket.swift) into your project.

### Create a [singleton](https://en.wikipedia.org/wiki/Singleton_pattern) class to hold an ACClient
```swift
// MyClient.swift

import ACActionCable

class MyClient {

    static let shared = MyClient()
    private let client: ACClient

    private init() {
        let socket = ACStarscreamWebSocket(stringURL: "https://myrailsapp.com/cable") // Your concrete implementation of ACWebSocketProtocol (see above)
        client = ACClient(socket: socket, connectionMonitorTimeout: 6) // Leave connectionMonitorTimeout nil to disable connection monitoring
    }
}
```

### Connect and disconnect
You can set custom headers based on your server's requirements
```swift
// MyClient.swift

func connect() {
    client.headers = [
        "Auth": "Token",
        "Origin": "https://myrailsapp.com",
    ]
    client.connect()
}

func disconnect() {
    client.disconnect()
}
```
You probably want to connect and disconnect when your app becomes active or resigns active.
```swift
// SceneDelegate.swift

func sceneDidBecomeActive(_ scene: UIScene) {
   MyClient.shared.connect()
}

func sceneWillResignActive(_ scene: UIScene) {
    MyClient.shared.disconnect()
}
```
You probably also want to connect or disconnect when a user logs in or out.

### Subscribe and unsubscribe
```swift
// MyClient.swift

func subscribe(to channelIdentifier: ACChannelIdentifier, with messageHandler: @escaping ACMessageHandler) -> ACSubscription {
    client.subscribe(to: channelIdentifier, with: messageHandler)!
}

func unsubscribe(from subscription: ACSubscription) {
    client.unsubscribe(from: subscription)
}
```
```swift
// ChatChannel.swift

import ACActionCable

class ChatChannel {

    private var subscription: ACSubscription?

    func subscribe(to roomId: Int) {
        let channelIdentifier = ACChannelIdentifier(channelName: "ChatChannel", identifier: ["room_id": roomId])!
        subscription = MyClient.shared.subscribe(to: channelIdentifier, with: handleMessage(_:))
    }
    
    func unsubscribe() {
        guard let subscription = subscription else { return }
        MyClient.shared.unsubscribe(from: subscription)
    }

    private func handleMessage(_ message: ACMessage) {
        switch message.type {
        case .confirmSubscription:
            print("ChatChannel subscribed")
        default:
            // TODO: Use MyObject (see below)
            break
        }
    }
}
```

### Register your [`Decodable`](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types) messages
ACActionCable automatically decodes your models. For example, if your server broadcasts the following message:
```json
{
  "identifier":"{\"channel\":\"ChatChannel\",\"room_id\":42}",
  "message": {
    "my_object":{
      "sender_id": 311,
      "text": "Hello, room 42!"
    }
  }
}
```
Then ACActionCable can automatically decode it into the following object:
```swift
// MyObject.swift

struct MyObject: Codable { // Must implement Decodable or Codable
    let senderId: Int
    let text: String
}
```
All you have to do is register the object.
```swift
// MyClient.swift

private init() {
  // ...
  ACMessageBodyObject.register(MyObject.self)
}
```
```swift
// ChatChannel.swift

private func handleMessage(_ message: ACMessage) {
    switch message.type {
    case .confirmSubscription:
        print("Subscribed")
    default:
        switch message.body {
        case .dictionary(let dictionary):
            switch dictionary.object {
            case let myObject as MyObject:
                print("Received message from sender \(myObject.senderId): \(myObject.text)")
                // Received message from sender 311: "Hello, room 42!"
            default:
                print("Warning: ChatChannel ignored unrecognized message")
            }
        default:
            break
        }
    }
}

```

### Send messages
ACActionCable automatically encodes your [`Encodable`](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types) objects too:
```swift
// MyObject.swift

struct MyObject: Codable { // Must implement Encodable or Codable
    let senderId: Int
    let text: String
}
```
```swift
// ChatChannel.swift

func speak(_ text: String) {
    subscription?.send(actionName: "speak", object: MyObject(senderId: 99, text: text))
}
```
Calling `channel.speak("my message")` would cause the following to be sent:
```json
{
    "command":"message",
    "data":"{\"action\":\"speak\",\"my_object\":{\"sender_id\":99,\"text\":\"my message\"}}",
    "identifier":"{\"channel\":\"ChatChannel\",\"room_id\":42}"
}
```

### (Optional) Modify encoder/decoder date formatting
By default, `Date` objects are encoded or decoded using [`.secondsSince1970`](https://developer.apple.com/documentation/foundation/jsonencoder/dateencodingstrategy/secondssince1970). If you need to change to another format:
```swift
ACCommand.encoder.dateEncodingStrategy = .iso8601 // or any other JSONEncoder.DateEncodingStrategy
ACMessage.decoder.dateDecodingStrategy = .iso8601 // or any other JSONDecoder.DateDecodingStrategy
```

### (Optional) Add an ACClientTap
If you need to listen to the internal state of `ACClient`, use `ACClientTap`.
```swift
// MyClient.swift

private init() {
    // ...
    let tap = ACClientTap(
        onConnected: { (headers) in
            print("Client connected with headers: \(headers.debugDescription)")
        }, onDisconnected: { (reason) in
            print("Client disconnected with reason: \(reason.debugDescription)")
        }, onText: { (text) in
            print("Client received text: \(text)")
        }, onMessage: { (message) in
            print("Client received message: \(message)")
        })
    client.add(tap)
}
```

## Contributing
Instead of opening an issue, please fix it yourself and then [create a pull request](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork). Please add new tests for your feature or fix, and don't forget to make sure that all the tests pass!
