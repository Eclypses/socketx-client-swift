//// The MIT License (MIT)
//
// Copyright (c) Eclypses, Inc.
//
// All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import Foundation

final class Transport: Transportable {

    // Store the task directly. It is guaranteed to exist.
    private let webSocketTask: URLSessionWebSocketTask
    
    var onMessage: ((ActionByte, UInt8, Data) -> Void)?

    // Track if socket is open
    // This is read by Manager to know when to send the initial handshake.
    private(set) var isConnected = false

    /// Initialize with an existing WebSocketTask.
    /// The task is created by the customer's URLSession configuration.
    init(task: URLSessionWebSocketTask) {
        self.webSocketTask = task
    }

    func connect() {
        // Resume the task (starts the connection if suspended)
        webSocketTask.resume()
        
        // Mark as connected so Manager knows it can proceed with Handshake
        isConnected = true
        
        // Start the recursive receive loop
        receive()
    }

    func disconnect() {
        webSocketTask.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }

    func send(action: ActionByte, messageType: UInt8, payload: Data) {
        guard isConnected else {
            reportError(.transportError(reason: "WebSocket not connected"), self)
            return
        }

        // Wrap payload with MTE/SocketX headers
        let messageData = Header.wrap(action: action, messageType: messageType, payload: payload)
        
        webSocketTask.send(.data(messageData)) { error in
            if let error = error {
                reportError(.transportError(reason: "Send error: \(error)"), self)
                return
            }
        }
    }

    private func receive() {
        // Recursively listen for messages
        webSocketTask.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                // Report error and disconnect
                reportError(.transportError(reason: "Receive error: \(error)"), self)
                self.isConnected = false
                return // Stop recursion

            case .success(let message):
                switch message {
                case .data(let data):
                    // Attempt to unwrap MTE headers
                    if let (action, messageType, payload) = Header.unwrap(data) {
                        self.onMessage?(action, messageType, payload)
                    }
                case .string(let text):
                    // Fallback for plain text frames (treated as Proxy Text)
                    let payload = Data(text.utf8)
                    self.onMessage?(.proxyData, 0, payload)
                @unknown default:
                    break
                }
            }

            // Continue receiving only if still connected
            if self.isConnected {
                self.receive()
            }
        }
    }
}
