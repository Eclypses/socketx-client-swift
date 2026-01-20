<center>
<img src="Eclypses.png" style="width:50%;"/>
</center>

<div align="center" style="font-size:40pt; font-weight:900; font-family:arial; margin-top:50px;" >
SocketX Mobile Client  
Swift Package</div>

![Latest Release](https://img.shields.io/github/v/release/Eclypses/socketx-client-swift?style=flat-square)

## Introduction
This Swift Package provides the Eclypses SocketX Mobile Client for iOS. It enables secure, persistent WebSocket communication between your iOS app and your backend services via a SocketX server. You must have licensed access to a SocketX server instance. [More Info](https://eclypses.com/mte-technology/amazon-web-services-aws/)

**Purpose of SocketX:**
- Establish persistent, encrypted WebSocket tunnels to your server
- Protect real-time data with MTE encryption
- Support bidirectional messaging with automatic encryption/decryption
- Enable secure pub/sub and room-based communication patterns

## Quick Links

📚 **[Official Getting Started Guide](https://public-docs.eclypses.com/docs/socketx-server/client-libraries/iOS)** - Concise guide for experienced developers

💡 This README provides comprehensive reference documentation with detailed examples suitable for developers at all experience levels. If you're already familiar with Swift async/await, WebSockets, and MTE concepts, the official docs above offer a faster quick-start path.

## Prerequisites

- **iOS 14.0 or later** - Required because this library uses modern WebSocket APIs and Swift concurrency features (async/await) that were stabilized in iOS 14
- **Swift 5.5 or later** - Needed for async/await support, which is used in the initialization and connection lifecycle
- **Xcode 13.0 or later** - For Swift 5.5 support and iOS 14.0 deployment
- **Access to a licensed SocketX server instance** - This client library communicates with a SocketX server that handles the MTE encryption/decryption relay. You'll need the server URL and proper licensing credentials

## How SocketX Works

Before diving into the code, it's helpful to understand how SocketX creates a secure communication tunnel:

**Traditional WebSocket (Unencrypted):**
```
[Your iOS App] ←→ WebSocket ←→ [Your Backend Server]
    ⚠️ Data transmitted in plaintext (even with WSS/TLS, data is visible at endpoints)
```

**With SocketX (MTE-Encrypted):**
```
[Your iOS App] ←→ Encrypted WebSocket Tunnel ←→ [SocketX Server] ←→ [Your Backend Service]
     ↑                                                    ↑
  Encrypts here                                   Decrypts & forwards here
```

**Data Flow:**

1. **Pairing:** When your app connects, it performs an automatic MTE pairing handshake with the SocketX server using post-quantum Kyber-512 key exchange
2. **Encode:** Your app sends data (text or binary) through the SocketX client, which encrypts it using MTE
3. **Tunnel:** The encrypted payload travels over the WebSocket connection to the SocketX server
4. **Decode:** The server decrypts the payload using its paired MTE decoder
5. **Forward:** The server forwards the original data to your designated backend service or room
6. **Response:** Any response follows the same path in reverse - encrypted by the server, sent through the tunnel, decrypted by your app

**Key Benefits:**
- End-to-end encryption that's quantum-resistant (Kyber-512)
- Zero-trust architecture - data is encrypted before leaving your app
- Persistent connections for real-time, low-latency messaging
- Automatic reconnection and pairing management

## Installation

### Swift Package Manager (Recommended)

1. In Xcode, go to **File > Add Packages...**
2. Enter the package URL: `https://github.com/Eclypses/socketx-client-swift.git`
3. Select the version rule (we recommend "Up to Next Major Version")
4. Click **Add Package**
5. Select the target(s) where you want to use SocketX
6. Click **Add Package** again to confirm

**Common SPM Issues:**
- **"Package resolution failed"** - Make sure you have a stable internet connection and GitHub is accessible
- **"Failed to clone repository"** - Verify you have access to the repository (some versions may be private)
- **Build errors after adding package** - Try **Product > Clean Build Folder** (Cmd+Shift+K) and rebuild


## Setup

### Step 1: Configure Your SocketX Server

**Important:** 
Before using this client library, ensure your SocketX server is set up and configured to receive encrypted WebSocket connections from your iOS app. The server acts as a secure relay, handling MTE encryption/decryption and forwarding messages to your backend services or managing room-based communication.

### Step 2: Understanding Dependency Injection

**What is Dependency Injection?**
The SocketX client uses a dependency injection pattern, which means **you** create and configure the WebSocket connection, then pass it to the SocketX client. This gives you complete control over network configuration while the SocketX client handles encryption.

**Why use this pattern?**
- ✅ Add custom HTTP headers (authentication, API keys, etc.)
- ✅ Implement certificate pinning for enhanced security
- ✅ Configure timeouts, cookies, and network policies
- ✅ Use your own URLSessionDelegate for fine-grained control
- ✅ Test with mock WebSocket implementations

### Step 3: Import the Module

In any Swift file where you'll use SocketX, add the import statement:

```swift
import SocketXClient
```

### Step 4: Create and Configure Your WebSocket Connection

Here's a complete example of setting up SocketX in a typical iOS app:

```swift
import Foundation
import SocketXClient

// This class manages your secure WebSocket communication through SocketX
class ChatManager {
    // The SocketX client instance handles all encrypted communication
    private var socketXClient: SocketXClient?
    var isConnected: Bool = false
    
    // Store your SocketX server URL and room path
    let socketXServerUrl: String
    let roomPath: String
    
    init(serverUrl: String, room: String) {
        self.socketXServerUrl = serverUrl
        self.roomPath = room
    }
    
    /// Establishes a secure connection to the SocketX server
    func connect() {
        // Step 1: Build the WebSocket URL
        // Format: wss://your-server.com/room-name
        // The path (e.g., "/chat-room-1") determines which room you join
        let fullUrl = "\(socketXServerUrl)\(roomPath)"
        guard let url = URL(string: fullUrl) else {
            print("❌ Invalid URL: \(fullUrl)")
            return
        }
        
        // Step 2: Configure URLSession
        // This is where you add custom headers, authentication, etc.
        let config = URLSessionConfiguration.default
        
        // Example: Add authorization header
        config.httpAdditionalHeaders = [
            "Authorization": "Bearer your-auth-token",
            "X-API-Key": "your-api-key"
        ]
        
        // Optional: Configure timeout
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        
        // Create the URLSession
        let session = URLSession(configuration: config, 
                                delegate: nil, 
                                delegateQueue: nil)
        
        // Step 3: Create the WebSocket task
        // IMPORTANT: Do NOT call .resume() - SocketXClient manages the lifecycle
        let task = session.webSocketTask(with: url)
        
        // Step 4: Initialize SocketXClient with dependency injection
        do {
            // Pass the task to SocketXClient
            // This validates MTE licensing and prepares for pairing
            socketXClient = try SocketXClient(task: task)
            
            // Step 5: Set up event callbacks
            setupCallbacks()
            
            // Step 6: Initiate the connection
            // This triggers:
            // 1. WebSocket connection establishment
            // 2. Automatic MTE pairing handshake
            // 3. Room connection
            socketXClient?.connect()
            
            print("🔄 Connecting to SocketX server...")
            
        } catch {
            print("❌ SocketX initialization failed: \(error)")
            // Common errors:
            // - MTE license validation failure
            // - Invalid task configuration
        }
    }
    
    private func setupCallbacks() {
        // Called when connection is established AND MTE pairing is complete
        socketXClient?.onConnected = { [weak self] in
            self?.isConnected = true
            print("✅ Securely connected to SocketX server")
            print("🔐 MTE encryption active")
            
            // Now safe to send/receive messages
            DispatchQueue.main.async {
                // Update your UI - show "Connected" status
                // Enable send button, etc.
            }
        }
        
        // Called when receiving text messages (automatically decrypted)
        socketXClient?.onMessageReceived = { [weak self] text in
            print("📨 Received text: \(text)")
            
            // Parse the message (e.g., JSON)
            // Update your UI with new data
            DispatchQueue.main.async {
                // self?.handleIncomingMessage(text)
            }
        }
        
        // Called when receiving binary data (automatically decrypted)
        socketXClient?.onBinaryReceived = { [weak self] data in
            print("📦 Received binary: \(data.count) bytes")
            
            // Process binary data (images, files, etc.)
            DispatchQueue.main.async {
                // self?.handleBinaryData(data)
            }
        }
        
        // Called when errors occur
        socketXClient?.onError = { [weak self] error in
            self?.isConnected = false
            
            switch error {
            case .codecError(let reason):
                // MTE encryption/decryption error
                print("❌ MTE Error: \(reason)")
                // This might indicate:
                // - Pairing state mismatch
                // - Corrupted data
                // - Need to reconnect
                
            case .networkError(let reason):
                // WebSocket or network error
                print("❌ Network Error: \(reason)")
                // This might indicate:
                // - Connection lost
                // - Server unavailable
                // - Timeout
                
            default:
                // Handle other errors
            }
            
            DispatchQueue.main.async {
                // Update UI - show error, retry button, etc.
                // self?.showError(error)
            }
        }
    }
    
    /// Disconnects from the SocketX server
    func disconnect() {
        socketXClient?.disconnect()
        isConnected = false
        print("🔌 Disconnected from SocketX server")
    }
    
    /// Sends a text message (will be encrypted automatically)
    func sendMessage(_ text: String) {
        guard isConnected else {
            print("⚠️ Cannot send - not connected")
            return
        }
        
        socketXClient?.send(text: text)
        print("📤 Sent text: \(text)")
    }
    
    /// Sends binary data (will be encrypted automatically)
    func sendBinary(_ data: Data) {
        guard isConnected else {
            print("⚠️ Cannot send - not connected")
            return
        }
        
        socketXClient?.send(binary: data)
        print("📤 Sent binary: \(data.count) bytes")
    }
}
```

**Understanding async/await context:**
Note that `SocketXClient.init()` uses `throws` (not `async throws`), so you can initialize it in regular synchronous code. The `connect()` method is also synchronous - it starts the connection process and returns immediately. You'll receive confirmation through the `onConnected` callback.

**Example usage in a SwiftUI view:**
```swift
struct ChatView: View {
    @StateObject private var chatManager = ChatManager(
        serverUrl: "wss://your-socketx-server.com",
        room: "/chat-room-1"
    )
    @State private var messageText = ""
    
    var body: some View {
        VStack {
            Text(chatManager.isConnected ? "🟢 Connected" : "🔴 Disconnected")
                .padding()
            
            TextField("Type message...", text: $messageText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Button("Send") {
                chatManager.sendMessage(messageText)
                messageText = ""
            }
            .disabled(!chatManager.isConnected)
        }
        .onAppear {
            chatManager.connect()
        }
        .onDisappear {
            chatManager.disconnect()
        }
    }
}
```

**Example usage in a UIKit view controller:**
```swift
class ChatViewController: UIViewController {
    var chatManager: ChatManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the chat manager
        chatManager = ChatManager(
            serverUrl: "wss://your-socketx-server.com",
            room: "/chat-room-1"
        )
        
        // Connect to SocketX server
        chatManager.connect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Clean up connection
        chatManager.disconnect()
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let text = messageTextField.text, !text.isEmpty else { return }
        chatManager.sendMessage(text)
        messageTextField.text = ""
    }
}
```

## Usage

### Sending Messages

Once connected, you can send text or binary messages. The SocketX client automatically encrypts all outgoing data before transmission.

#### Sending Text Messages

Text messages are typically JSON strings, chat messages, or any string-based protocol.

```swift
// Send a simple text message
socketXClient?.send(text: "Hello, World!")

// Send JSON data
let jsonData = ["type": "chat", "message": "Hello", "userId": "123"]
if let jsonString = try? JSONSerialization.data(withJSONObject: jsonData),
   let text = String(data: jsonString, encoding: .utf8) {
    socketXClient?.send(text: text)
}

// Send a Codable struct as JSON
struct ChatMessage: Codable {
    let type: String
    let content: String
    let timestamp: Date
}

let message = ChatMessage(type: "chat", content: "Hello", timestamp: Date())
if let encoded = try? JSONEncoder().encode(message),
   let jsonString = String(data: encoded, encoding: .utf8) {
    socketXClient?.send(text: jsonString)
}
```

#### Sending Binary Data

Binary messages are useful for images, files, audio, video, or custom binary protocols.

```swift
// Send raw bytes
let bytes: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F]  // "Hello" in hex
let data = Data(bytes)
socketXClient?.send(binary: data)

// Send an image
if let image = UIImage(named: "photo"),
   let imageData = image.jpegData(compressionQuality: 0.8) {
    socketXClient?.send(binary: imageData)
    print("📤 Sent image: \(imageData.count) bytes")
}

// Send a file
let fileURL = URL(fileURLWithPath: "/path/to/file.pdf")
if let fileData = try? Data(contentsOf: fileURL) {
    socketXClient?.send(binary: fileData)
    print("📤 Sent file: \(fileData.count) bytes")
}

// Send MessagePack or Protobuf data
// (Any binary serialization format works)
```

**Important Notes:**
- All data is automatically encrypted using MTE before transmission
- There's no separate "secure send" method - all sends are secure
- Make sure you're connected before sending (check `isConnected` or rely on `onConnected` callback)

### Receiving Messages

Messages arrive through the callback handlers you set up. The SocketX client automatically decrypts all incoming data.

#### Receiving Text Messages

```swift
socketXClient?.onMessageReceived = { text in
    print("📨 Received: \(text)")
    
    // Parse JSON
    if let data = text.data(using: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        
        let messageType = json["type"] as? String
        let content = json["message"] as? String
        
        print("Type: \(messageType ?? "unknown")")
        print("Content: \(content ?? "none")")
    }
    
    // Or decode directly into a struct
    if let data = text.data(using: .utf8),
       let message = try? JSONDecoder().decode(ChatMessage.self, from: data) {
        print("Decoded message: \(message.content) at \(message.timestamp)")
    }
    
    // Update UI on main thread
    DispatchQueue.main.async {
        // self.tableView.reloadData()
        // self.messageLabel.text = text
    }
}
```

#### Receiving Binary Data

```swift
socketXClient?.onBinaryReceived = { data in
    print("📦 Received binary: \(data.count) bytes")
    
    // Display an image
    if let image = UIImage(data: data) {
        DispatchQueue.main.async {
            // self.imageView.image = image
        }
    }
    
    // Save a file
    let documentsURL = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )[0]
    let fileURL = documentsURL.appendingPathComponent("received-file.dat")
    
    try? data.write(to: fileURL)
    print("💾 Saved to: \(fileURL.path)")
    
    // Parse custom binary protocol
    // let header = data.subdata(in: 0..<4)
    // let payload = data.subdata(in: 4..<data.count)
}
```

### Connection Lifecycle Management

#### Monitoring Connection Status

```swift
// Track connection state
private var isConnected = false

socketXClient?.onConnected = { [weak self] in
    self?.isConnected = true
    print("✅ Connected")
    
    // Enable UI elements
    DispatchQueue.main.async {
        self?.sendButton.isEnabled = true
        self?.statusLabel.text = "Connected"
        self?.statusLabel.textColor = .systemGreen
    }
}

socketXClient?.onError = { [weak self] error in
    self?.isConnected = false
    print("❌ Disconnected due to error")
    
    // Disable UI elements
    DispatchQueue.main.async {
        self?.sendButton.isEnabled = false
        self?.statusLabel.text = "Disconnected"
        self?.statusLabel.textColor = .systemRed
    }
}
```

#### Manual Disconnection

```swift
// Gracefully disconnect when done
func cleanup() {
    socketXClient?.disconnect()
    socketXClient = nil
    isConnected = false
}

// Call in appropriate lifecycle methods
// SwiftUI: .onDisappear { cleanup() }
// UIKit: viewWillDisappear or deinit
```

#### Room-Based Communication

The SocketX server supports room-based messaging, where the URL path determines which room you join. This enables pub/sub patterns and isolated communication channels.

```swift
// Different rooms for different purposes
class MultiRoomManager {
    var chatClient: SocketXClient?
    var notificationClient: SocketXClient?
    
    func connectToChatRoom() {
        let url = URL(string: "wss://your-server.com/chat/room-1")!
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.webSocketTask(with: url)
        
        chatClient = try? SocketXClient(task: task)
        chatClient?.onMessageReceived = { text in
            print("💬 Chat message: \(text)")
        }
        chatClient?.connect()
    }
    
    func connectToNotifications() {
        let url = URL(string: "wss://your-server.com/notifications/user-123")!
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.webSocketTask(with: url)
        
        notificationClient = try? SocketXClient(task: task)
        notificationClient?.onMessageReceived = { text in
            print("🔔 Notification: \(text)")
        }
        notificationClient?.connect()
    }
    
    func broadcastToRoom(_ message: String) {
        // Send to chat room - all connected clients in that room will receive it
        chatClient?.send(text: message)
    }
}
```

**URL Path Examples:**
- `/chat/general` - General chat room
- `/chat/private/user123` - Private user-specific room
- `/notifications/user123` - User-specific notification channel
- `/game/match-456` - Game-specific room
- `/stream/video-1` - Streaming channel

The SocketX server determines routing and message distribution based on these paths.

## Error Handling

Understanding and properly handling errors is crucial for a robust implementation.

### Error Types

The `SocketXClientError` enum defines all possible error cases:

```swift
public enum SocketXClientError: Error {
    case codecError(String)      // MTE encryption/decryption error
    case networkError(String)    // WebSocket or network error
}
```

### Comprehensive Error Handling

```swift
socketXClient?.onError = { error in
    switch error {
    case .codecError(let reason):
        print("❌ MTE Codec Error: \(reason)")
        
        // Possible causes:
        // - Pairing state desynchronized
        // - Corrupted encrypted data received
        // - MTE encoder/decoder failure
        
        // Recommended actions:
        // 1. Log the error for diagnostics
        // 2. Disconnect and reconnect (forces re-pairing)
        // 3. Alert user if problem persists
        
        logError("Codec error: \(reason)")
        scheduleReconnect()
        
    case .networkError(let reason):
        print("❌ Network Error: \(reason)")
        
        // Possible causes:
        // - Connection lost (user went offline)
        // - Server shut down or restarted
        // - Network timeout
        // - DNS resolution failure
        
        // Recommended actions:
        // 1. Check network reachability
        // 2. Implement exponential backoff reconnection
        // 3. Show user-friendly message
        
        if isNetworkAvailable() {
            attemptReconnectWithBackoff()
        } else {
            showAlert("Network unavailable. Will retry when online.")
        }
        
}

// Helper functions
func logError(_ message: String) {
    // Send to analytics, crash reporting, etc.
    print("📝 Logged: \(message)")
}

func isNetworkAvailable() -> Bool {
    // Use Network framework or Reachability library
    return true
}

func showAlert(_ message: String) {
    DispatchQueue.main.async {
        // Show UIAlertController or SwiftUI alert
    }
}
```

### Preventing Common Errors

**1. Don't send before connected:**
```swift
func sendMessage(_ text: String) {
    guard isConnected else {
        print("⚠️ Not connected - message queued")
        pendingMessages.append(text)
        return
    }
    socketXClient?.send(text: text)
}

// Send queued messages when connected
socketXClient?.onConnected = { [weak self] in
    self?.isConnected = true
    self?.pendingMessages.forEach { message in
        self?.socketXClient?.send(text: message)
    }
    self?.pendingMessages.removeAll()
}
```

**2. Handle initialization errors:**
```swift
do {
    socketXClient = try SocketXClient(task: task)
} catch {
    print("❌ Initialization error: \(error)")
    
    // Possible issues:
    // - Invalid MTE license (check Settings.swift)
    // - Invalid task configuration
    
    if let error = error as? SocketXClientError {
        // Handle specific error type
    }
}
```

**3. Clean up resources:**
```swift
class MyViewController: UIViewController {
    var socketXClient: SocketXClient?
    
    deinit {
        // Always disconnect to free resources
        socketXClient?.disconnect()
        socketXClient = nil
    }
}
```

## Troubleshooting

This section covers common issues and their solutions.

### Connection Issues

**Problem: Connection fails immediately**
```swift
// Error: "Network Error: The operation couldn't be completed"
```
**Solutions:**
1. **Verify server URL is correct:**
   ```swift
   // ✅ Correct
   let url = URL(string: "wss://your-server.com/room")!
   
   // ❌ Wrong - missing protocol
   let url = URL(string: "your-server.com/room")!
   
   // ❌ Wrong - using http instead of ws
   let url = URL(string: "https://your-server.com/room")!
   ```

2. **Check server is running and accessible:**
   ```bash
   # Test WebSocket connectivity (requires wscat)
   wscat -c wss://your-server.com/test
   ```

3. **Verify network permissions in Info.plist:**
   ```xml
   <!-- For HTTP servers (not recommended for production) -->
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsArbitraryLoads</key>
       <true/>
   </dict>
   ```

4. **Check firewall/VPN isn't blocking WebSocket connections**

---

**Problem: "Pairing Error: ..." during connection**
**Solutions:**
1. **Verify MTE license is valid:**
   - Check [Settings.swift](SocketXClient/Settings.swift) has correct license keys
   - Ensure license hasn't expired
   - Contact Eclypses support if needed

2. **Confirm server MTE configuration matches client**

3. **Check server logs** for pairing rejection reasons

---

**Problem: Connects in simulator but fails on device**
**Solutions:**
1. **Check device network connectivity** (Wi-Fi vs cellular)
2. **Verify server URL is accessible from device** (not localhost)
3. **Review certificate pinning configuration** if implemented
4. **Check code signing and provisioning profiles**

---

### Message Issues

**Problem: Messages sent but not received by server**
**Solutions:**
1. **Verify you're connected before sending:**
   ```swift
   guard isConnected else {
       print("⚠️ Not connected")
       return
   }
   socketXClient?.send(text: message)
   ```

2. **Check server logs** to confirm messages are arriving

3. **Verify room path is correct** (messages only go to the specified room)

4. **Enable debugging to inspect traffic:**
   ```swift
   // Add debug print in send methods
   socketXClient?.send(text: message)
   print("📤 DEBUG: Sent message to room: \(roomPath)")
   ```

---

**Problem: Can send but not receive messages**
**Solutions:**
1. **Verify callback is set up before connecting:**
   ```swift
   // ✅ Correct order
   socketXClient = try SocketXClient(task: task)
   socketXClient?.onMessageReceived = { text in
       print("📨 \(text)")
   }
   socketXClient?.connect()
   
   // ❌ Wrong - callback set after connect
   socketXClient?.connect()
   socketXClient?.onMessageReceived = { /* ... */ }
   ```

2. **Check for strong reference cycles:**
   ```swift
   // ✅ Use [weak self] to prevent memory issues
   socketXClient?.onMessageReceived = { [weak self] text in
       self?.handleMessage(text)
   }
   ```

3. **Ensure messages are being sent to your room** (check server configuration)

---

**Problem: "Codec Error: ..." when receiving messages**
**Solutions:**
1. **Disconnect and reconnect to re-establish pairing:**
   ```swift
   socketXClient?.disconnect()
   // Wait a moment
   DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
       self.socketXClient?.connect()
   }
   ```

2. **Verify all clients/servers are using compatible MTE versions**

3. **Check for data corruption** (network issues, proxy interference)

---

### Performance Issues

**Problem: High memory usage**
**Solutions:**
1. **Don't accumulate messages indefinitely:**
   ```swift
   var messages: [String] = []
   let maxMessages = 100
   
   socketXClient?.onMessageReceived = { [weak self] text in
       self?.messages.append(text)
       
       // Trim old messages
       if self!.messages.count > maxMessages {
           self?.messages.removeFirst()
       }
   }
   ```

2. **Process binary data immediately rather than storing:**
   ```swift
   socketXClient?.onBinaryReceived = { data in
       // ✅ Process immediately
       self.processImage(data)
       
       // ❌ Don't store large data unnecessarily
       // self.allImages.append(data)  // Accumulates memory
   }
   ```

3. **Disconnect when not needed:**
   ```swift
   // Disconnect when app goes to background
   NotificationCenter.default.addObserver(
       forName: UIApplication.didEnterBackgroundNotification,
       object: nil,
       queue: .main
   ) { _ in
       self.socketXClient?.disconnect()
   }
   ```

---

**Problem: Slow message delivery**
**Solutions:**
1. **Check network conditions** (Wi-Fi vs cellular, signal strength)

2. **Use `.responsiveData` network service type:**
   ```swift
   let config = URLSessionConfiguration.default
   config.networkServiceType = .responsiveData
   ```

3. **Minimize message size** (compress data, use binary instead of JSON for large payloads)

4. **Check server performance** (may be bottleneck)

---

### Platform-Specific Issues

**Problem: App crashes when reconnecting**
**Solutions:**
1. **Properly clean up old instances:**
   ```swift
   func reconnect() {
       // Clean up existing connection
       socketXClient?.disconnect()
       socketXClient = nil
       
       // Create new connection
       let task = session.webSocketTask(with: url)
       socketXClient = try? SocketXClient(task: task)
       setupCallbacks()
       socketXClient?.connect()
   }
   ```

2. **Check for retain cycles** with Instruments

---

**Problem: Connection drops when app goes to background**
**Solutions:**
1. **iOS suspends background network activity by design**
   - This is normal behavior for iOS apps
   - WebSocket connections are terminated when app is suspended

2. **Implement background task if needed (limited time):**
   ```swift
   var backgroundTask: UIBackgroundTaskIdentifier = .invalid
   
   func handleAppBackground() {
       backgroundTask = UIApplication.shared.beginBackgroundTask {
           // Clean up when time expires
           self.socketXClient?.disconnect()
           UIApplication.shared.endBackgroundTask(self.backgroundTask)
       }
   }
   ```

3. **Reconnect when app returns to foreground:**
   ```swift
   NotificationCenter.default.addObserver(
       forName: UIApplication.willEnterForegroundNotification,
       object: nil,
       queue: .main
   ) { _ in
       self.socketXClient?.connect()
   }
   ```

---

### Debugging Tips

1. **Add detailed logging:**
   ```swift
   print("🔄 State: Initializing SocketXClient")
   socketXClient = try? SocketXClient(task: task)
   
   print("🔄 State: Setting up callbacks")
   setupCallbacks()
   
   print("🔄 State: Connecting")
   socketXClient?.connect()
   ```

2. **Monitor callback invocations:**
   ```swift
   socketXClient?.onConnected = {
       print("✅ CALLBACK: onConnected fired")
       self.isConnected = true
   }
   
   socketXClient?.onError = { error in
       print("❌ CALLBACK: onError fired - \(error)")
   }
   ```

3. **Use Instruments** to profile network activity and memory

4. **Check both client and server logs** - issues can be on either side

5. **Test with a simple echo server first** to isolate client vs server issues

---

### Getting Help

If you're still experiencing issues after trying these solutions:

1. **Gather information:**
   - iOS version and device model
   - SocketX client library version
   - Complete error messages
   - Steps to reproduce
   - Server-side logs (if available)

2. **Check official documentation:**
   - [Getting Started Guide](https://public-docs.eclypses.com/docs/socketx-server/client-libraries/iOS)
   - Server-side SocketX documentation

3. **Contact support:**
   - **Email:** [info@eclypses.com](mailto:info@eclypses.com)
   - **Developer Portal:** [developers.eclypses.com/dashboard](https://developers.eclypses.com/dashboard)
   - Include all gathered information and logs

## API Reference

Complete reference of the SocketX client API.

### SocketXClient Class

The main entry point for secure WebSocket communication.

#### Initialization

```swift
init(task: URLSessionWebSocketTask) throws
```

Initializes the SocketX client with a configured WebSocket task.

**Parameters:**
- `task` - A `URLSessionWebSocketTask` configured with your server URL and session settings. **Do not call `.resume()` on the task** - SocketX manages the lifecycle.

**Throws:**
- Error if MTE license validation fails
- Error if task configuration is invalid

**Example:**
```swift
let url = URL(string: "wss://your-server.com/room")!
let config = URLSessionConfiguration.default
let session = URLSession(configuration: config)
let task = session.webSocketTask(with: url)

let client = try SocketXClient(task: task)
```

---

#### Methods

##### `connect()`

```swift
func connect()
```

Initiates the WebSocket connection and MTE pairing process. This method returns immediately - use `onConnected` callback to know when connection is established.

**What it does:**
1. Establishes WebSocket connection
2. Performs MTE pairing handshake with server (Kyber-512 key exchange)
3. Sends room connection request
4. Triggers `onConnected` callback on success or `onError` on failure

**Example:**
```swift
client.connect()
```

---

##### `disconnect()`

```swift
func disconnect()
```

Gracefully closes the WebSocket connection and cleans up resources.

**Example:**
```swift
client.disconnect()
```

---

##### `send(text:)`

```swift
func send(text: String)
```

Sends a text message. The message is automatically encrypted using MTE before transmission.

**Parameters:**
- `text` - The text message to send (typically JSON string or plain text)

**Example:**
```swift
client.send(text: "Hello, World!")

// Send JSON
let json = "{\"type\":\"chat\",\"message\":\"Hello\"}"
client.send(text: json)
```

---

##### `send(binary:)`

```swift
func send(binary: Data)
```

Sends binary data. The data is automatically encrypted using MTE before transmission.

**Parameters:**
- `binary` - The binary data to send (images, files, custom binary protocols, etc.)

**Example:**
```swift
let data = Data([0x01, 0x02, 0x03])
client.send(binary: data)

// Send image
if let imageData = image.jpegData(compressionQuality: 0.8) {
    client.send(binary: imageData)
}
```

---

#### Callbacks

Set these closures to receive events from the SocketX client.

##### `onConnected`

```swift
var onConnected: (() -> Void)?
```

Called when the WebSocket connection is established AND MTE pairing is complete. At this point, you can safely send and receive messages.

**Example:**
```swift
client.onConnected = {
    print("✅ Ready to send/receive")
    self.isConnected = true
}
```

---

##### `onMessageReceived`

```swift
var onMessageReceived: ((String) -> Void)?
```

Called when a text message is received. The message is automatically decrypted before this callback is invoked.

**Parameters:**
- `String` - The decrypted text message

**Example:**
```swift
client.onMessageReceived = { text in
    print("📨 Received: \(text)")
    
    // Parse JSON
    if let data = text.data(using: .utf8),
       let json = try? JSONDecoder().decode(Message.self, from: data) {
        self.handleMessage(json)
    }
}
```

---

##### `onBinaryReceived`

```swift
var onBinaryReceived: ((Data) -> Void)?
```

Called when binary data is received. The data is automatically decrypted before this callback is invoked.

**Parameters:**
- `Data` - The decrypted binary data

**Example:**
```swift
client.onBinaryReceived = { data in
    print("📦 Received: \(data.count) bytes")
    
    // Display image
    if let image = UIImage(data: data) {
        self.imageView.image = image
    }
}
```

---

##### `onError`

```swift
var onError: ((SocketXClientError) -> Void)?
```

Called when an error occurs during connection, pairing, or message transmission.

**Parameters:**
- `SocketXClientError` - The error that occurred

**Example:**
```swift
client.onError = { error in
    switch error {
    case .codecError(let reason):
        print("❌ MTE Error: \(reason)")
    case .networkError(let reason):
        print("❌ Network Error: \(reason)")
    default:
        // Handle Error
    }
}
```

---

### SocketXClientError Enum

Defines all possible error types.

```swift
public enum SocketXClientError: Error {
    case codecError(String)      // MTE encryption/decryption error
    case networkError(String)    // WebSocket or network error  
}
```

**Error Cases:**

- **`codecError(String)`** - MTE encoder/decoder error. Usually indicates corrupted data or desynchronized pairing state. Reconnecting typically resolves this.

- **`networkError(String)`** - Network connectivity issue. Connection lost, server unreachable, timeout, etc. Check network availability and server status.

---

## Contact Eclypses  

**Email:** [info@eclypses.com](mailto:info@eclypses.com)  
**Web:** [www.eclypses.com](https://www.eclypses.com)  
**Developer Portal:** [developers.eclypses.com/dashboard](https://developers.eclypses.com/dashboard)

---  
**All trademarks of Eclypses Inc.** may not be used without Eclypses Inc.'s prior written consent.
