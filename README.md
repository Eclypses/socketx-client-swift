<center>
<img src="Eclypses.png" style="width:50%;"/>
</center>

<div align="center" style="font-size:40pt; font-weight:900; font-family:arial; margin-top:50px;" >
SocketX Mobile Client  
Swift Package</div>

![Latest Release](https://img.shields.io/github/v/release/Eclypses/socketx-client-swift?style=flat-square)

## Introduction  
This SPM package provides the Swift language **Eclypses SocketX Mobile Client Package**. It requires licensed access to a SocketX server instance to receive secure transmissions. [Info](https://eclypses.com/mte-technology/amazon-web-services-aws/)

**Purpose:**  
- Securely relay socket packets to your server.  
- Protect sensitive data with MTE encryption.   

## Overview  
The SocketX Mobile Client establishes a secure, persistent WebSocket connection to your SocketX Server, creating an encrypted tunnel for your application's data.

**Data Flow:**

1.  **Encode:** The SocketX client in your app takes the data payload (e.g., a JSON object) and encodes it using MTE.
2.  **Send:** It sends the encoded payload over the WebSocket connection to the SocketX Server.
3.  **Decode:** The server decodes the payload to retrieve the original data.
4.  **Forward:** The server then forwards this original data to the final destination service or API.

Any response from the destination service travels the same path in reverse: the server encodes the response and sends it back through the WebSocket, where the client decodes it before delivering it to your application.

## Installation

1.  **Add Package:** Add this [SocketX Package](https://github.com/Eclypses/socketx-client-swift.git) to your project via Swift Package Manager. [How To](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
2.  **Server Setup:** Ensure your SocketX Server is configured to receive requests from your application.
3.  **Link Binary:** Navigate to your target’s **General** pane, and in the "Frameworks, Libraries, and Embedded Content" section, confirm that the `SocketXClient` module is present.

## Getting Started

SocketXClient utilizes **Dependency Injection**. Instead of managing network configurations internally, you create a standard `URLSessionWebSocketTask` using your own `URLSession` configuration (allowing for custom headers, certificate pinning, cookies, etc.) and pass that task to the SocketXClient.

### 1. Configure your Session & Task
Create your `URLSession` and `URLSessionWebSocketTask`.
> **Note:** Do not call `.resume()` on the task immediately. The `SocketXClient` will handle the connection lifecycle.

```swift
// 1. Create a URL pointing to your SocketX Server and specific Room
//    The path (e.g. /my-room) determines the room connection.
guard let url = URL(string: "wss://my-socketx-server.com/my-room") else { return }

// 2. Configure URLSession (Add custom headers, auth tokens, etc.)
let config = URLSessionConfiguration.default
config.httpAdditionalHeaders = ["Authorization": "Bearer <YOUR_TOKEN>"]

let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)

// 3. Create the Task
let task = session.webSocketTask(with: url)
```

### 2. Initialize SocketXClient
Instantiate the client by passing the task you created.

```swift
import SocketXClient

class NetworkManager {

    private var socketXClient: SocketXClient?
    var isConnected: Bool = false

    func connect() {
        // ... (See Step 1 for task creation) ...
        
        do {
            // Inject the task into SocketXClient
            socketXClient = try SocketXClient(task: task)
            
            setupCallbacks()
            
            // Initiate the connection
            socketXClient?.connect()
            
        } catch {
            print("Initialization failed: \(error)")
        }
    }
    
    private func setupCallbacks() {
        // Connection established and MTE paired
        socketXClient?.onConnected = { [weak self] in 
            self?.isConnected = true
            print("Securely Connected")
        }

        // Handle incoming text messages
        socketXClient?.onMessageReceived = { [weak self] text in
            print("Received decrypted text: \(text)")
        }

        // Handle incoming binary data
        socketXClient?.onBinaryReceived = { [weak self] data in
            print("Received decrypted binary: \(data.count) bytes")
        }

        // Handle errors
        socketXClient?.onError = { [weak self] error in
            switch error {
            case .codecError(let reason):
                print("MTE Error: \(reason)")
            case .networkError(let reason):
                print("Network Error: \(reason)")
            default:
                print("Error: \(error)")
            }
            self?.isConnected = false
        }
    }

    func disconnect() {
        socketXClient?.disconnect()
    }
}
```

### Sending Data
Once connected, you can send strings or binary data directly. The client handles encryption automatically.

```swift
// Send Text
socketXClient?.send(text: "Hello World")

// Send Binary
let data = Data([0x01, 0x02, 0x03])
socketXClient?.send(binary: data)
```

## Contact Eclypses  

**Email:** [info@eclypses.com](mailto:info@eclypses.com)  
**Web:** [www.eclypses.com](https://www.eclypses.com)  
**Chat with us:** [Developer Portal](https://developers.eclypses.com/dashboard)  

---  
**All trademarks of Eclypses Inc.** may not be used without Eclypses Inc.'s prior written consent.
