<center>
<img src="Eclypses.png" style="width:50%;"/>
</center>

<div align="center" style="font-size:40pt; font-weight:900; font-family:arial; margin-top:50px;" >
SocketX Mobile Client  
Swift Package</div>

![Latest Release](https://img.shields.io/github/v/release/Eclypses/socketx-client-swift?style=flat-square)

## Introduction  
This SPM package provides the Swift language Eclypses SocketX Mobile Client Package and requires licensed access to a SocketX server instance to receive the secure transmission. [Info](https://eclypses.com/mte-technology/amazon-web-services-aws/)

**Purpose of MteRelay:**  
- Securely relay socket packets to your server.  
- Protect sensitive data with MTE encryption.   

## Overview  
The SocketX Mobile Client establishes a secure, persistent WebSocket connection to your SocketX Server, creating an encrypted tunnel for your application's data.


The data flow for an outgoing message is as follows:



1. The SocketX client in your app takes the data payload (e.g., a JSON object) and encodes it using MTE.

2. It sends the encoded payload over the WebSocket connection to the SocketX Server.

3. The server decodes the payload to retrieve the original data.

4. The server then forwards this original data to the final destination service or API.


Any response from the destination service travels the same path in reverse: the server encodes the response and sends it back through the WebSocket, where the client decodes it before delivering it to your application.

## Adding SocketX Mobile Client Swift Package to Your Application
1. Add this [SocketX Package](https://github.com/Eclypses/socketx-client-swift.git) - [HowTo](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
2. Set up corresponding SocketX Server to receive the requests from your application, where they will be decoded and relayed on to the original destination API.
3. Navigate to your target’s General pane, and in the "Frameworks, Libraries, and Embedded Content" section, confirm that the SocketXClient module is there. If not, add it.

## Table of Contents
- [Getting Started](#getting-started)
- [Contact Eclypses](#contact-eclypses)

## Getting Started  
Do the minimal setup which primarily consists of configuring the SocketX Server URL and editing your iOS application to use the SocketXClient.  SocketClient wraps URLSessionWebSocketTask so the same functionality is avaialble.

- Confirm that you have the SocketX Server URL available to instantiate the SocketXClient.
- Locate the URLSessionWebSocketTask function(s) in your application where your socket calls are made and:
    - Import SocketXClient
    - Create a socketXClient class variable, e.g. `private var socketXClient: SocketXClient?`


Your class interacting with `SocketXClient` must contain these elements:

```swift
import SocketXClient

class YourClass {

    private var socketXClient: SocketXClient?
    var isConnected: Bool = false

    disconnect()
            do {
                socketXClient = try SocketXClient(url: url)
                isConnected = true
            } catch {
                // Handle error appropriately
                isConnected = false
                return
            }
            
            socketXClient?.onMessageReceived = { [weak self] text in
                // Handle response text as you wish
            }
            socketXClient?.onBinaryReceived = { [weak self] data in
                // Handle response binary (Data) as you wish
            }
            socketXClient?.onError = { [weak self] error in
                switch error {
                case .codecError(let reason):
                    // Handle error appropriately
                case .networkError(let reason):
                    // Handle error appropriately
                default:
                    // Handle error appropriately
                }
                self?.isConnected = false
            }
            socketXClient?.onConnected = { [weak self] in 
                self?.isConnected = true
            }
            socketXClient?.connect()
}

// Also availble are these standard socket functions ...

socketXClient?.send(text: text)

socketXClient?.send(binary: data)

socketXClient?.disconnect()

```



## Contact Eclypses  

**Email:** [info@eclypses.com](mailto:info@eclypses.com)  
**Web:** [www.eclypses.com](https://www.eclypses.com)  
**Chat with us:** [Developer Portal](https://developers.eclypses.com/dashboard)  

---  
**All trademarks of Eclypses Inc.** may not be used without Eclypses Inc.'s prior written consent.
