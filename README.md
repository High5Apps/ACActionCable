# ACActionCable
[ACActionCable](https://github.com/High5Apps/ACActionCable) is a Swift 5.1 client for [Ruby on Rails](https://rubyonrails.org/) 6's [Action Cable](https://guides.rubyonrails.org/action_cable_overview.html) WebSocket server. It is a hard fork of [Action-Cable-Swift](https://github.com/nerzh/Action-Cable-Swift). It aims to be testable, dependency-free, and compliant with the Rails 6 Action Cable server.

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
        let socket = MyWebSocket(stringURL: "https://myrailsapp.com/cable") // Concrete implementation of ACWebSocketProtocol
        client = ACClient(ws: socket, connectionMonitorTimeout: 6) // Leave connectionMonitorTimeout nil to disable connection monitoring
    }
}
```

### Connect and disconnect
```swift
// MyClient.swift

func connect() {
    // Customize these optional headers based on your requirements
    client.headers = [
        "Auth": "Token",
        "Origin": "https://myrailsapp.com",
    ]
    client.connect()
}

func disconnect() {
    client.disconnect(allowReconnect: false)
}
```
```swift
// SceneDelegate.swift

func sceneDidBecomeActive(_ scene: UIScene) {
   MyClient.shared.connect()
}

func sceneWillResignActive(_ scene: UIScene) {
    MyClient.shared.disconnect()
}
```
You probably also want to connect/disconnect when a user logs in or out.

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
            // TODO: Use MyMessage (see below)
            break
        }
    }
}
```

### Register your `Decodable` messages
ACActionCable automatically decodes your models. For example, if your server broadcasts the following message:
```json
{
  "identifier":"{\"channel\":\"ChatChannel\",\"room_id\":42}",
  "message": {
    "my_message":{
      "sender_id": 311,
      "text": "Hello, room 42!"
    }
  }
}
```
```swift
// MyMessage.swift

struct MyMessage: Decodable { // Must implement Decodable
    let senderId: Int
    let text: String
}
```
```swift
// MyClient.swift

init() {
  // ...
  ACMessageBodyObject.register(MyMessage.self)
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
            case let myMessage as MyMessage:
                print("Received message from sender \(myMessage.senderId): \(myMessage.text)")
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
```swift
// ChatChannel.swift

func speak(_ text: String) {
    let data: [String: Any] = [
        "sender_id": 99,
        "text": text,
    ]
    subscription?.send(actionName: "speak", data: data)
}
```

### (Optional) Add an ACClientTap
If you need to listen to the internal state of `ACClient`, use `ACClientTap`.
```swift
// MyClient.swift

init() {
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
Instead of opening an issue, please fix it yourself and then [create a pull request](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork). Please add new tests for your feature or bug fix, and don't forget to make sure the tests all pass!
