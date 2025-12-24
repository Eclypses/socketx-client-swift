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
import Core

final public class SocketXClient {
    
    // MARK: - Singleton reference
    static weak var currentClient: SocketXClient?

    private let manager: Manager!

    // Public-facing closures
    public var onConnected: (() -> Void)?
    public var onMessageReceived: ((String) -> Void)?
    public var onBinaryReceived: ((Data) -> Void)?
    public var onError: ((SocketXError) -> Void)?

    // MARK: - Initializer

    /// Initialize with an existing URLSessionWebSocketTask.
    /// The customer creates this task using their custom URLSession.
    public init(task: URLSessionWebSocketTask) throws {
        
        // Check MTE licensing
        guard MteBase.initLicense(Settings.licCompanyName, Settings.licCompanyKey) else {
            debugLog("License Check failed")
            throw SocketXError.internalError(reason: "License Check failed")
        }
        debugLog("Using iOS SocketXClient Version \(Settings.socketXClientVersion) and MTE Version \(MteBase.getVersion())")
        
        // Initialize Manager with the task
        self.manager = Manager(task: task)
        
        // Set the singleton reference
        SocketXClient.currentClient = self

        setupCallbacks()
    }

    // MARK: - Private Setup

    private func setupCallbacks() {
        self.manager.onMessageReceived = { [weak self] text in
            DispatchQueue.main.async {
                self?.onMessageReceived?(text)
            }
        }
        self.manager.onBinaryReceived = { [weak self] data in
            DispatchQueue.main.async {
                self?.onBinaryReceived?(data)
            }
        }

        self.manager.onPaired = { [weak self] in
            DispatchQueue.main.async {
                self?.onConnected?()
            }
        }
    }

    // MARK: - Public Methods

    public func connect() {
        manager.connect()
    }

    public func disconnect() {
        manager.disconnect()
    }

    public func send(text: String) {
        manager.sendProxyData(text: text)
    }

    public func send(binary data: Data) {
        manager.sendProxyData(binary: data)
    }
}

// MARK: - Centralized error reporting
// (Remains unchanged - see previous snippet)
func reportError(_ error: SocketXError,
                 _ object: Any? = nil,
                 function: String = #function,
                 line: Int = #line) {
    
    let reason: String
    switch error {
    case .networkError(let r) : reason = r
    case .transportError(let r): reason = r
    case .codecError(let r): reason = r
    case .handshakeError(let r): reason = r
    case .proxyError(let r):  reason = r
    case .internalError(let r):   reason = r
    case .unknown(let r):  reason = r
    }
    debugLog(reason, object, function: function, line: line)
    DispatchQueue.main.async {
        SocketXClient.currentClient?.onError?(error)
    }
}

// (debugLog and SocketXError remain unchanged)
func debugLog(_ message: String,
              _ object: Any? = nil,
              function: String = #function,
              line: Int = #line) {
    #if DEBUG
    let className: String
    if let object = object {
        className = String(describing: type(of: object))
    } else {
        className = "Global"
    }
    print("[\(className) \(function) line:\(line)] \(message)")
    #endif
}

public enum SocketXError: Error {
    case networkError(reason: String)
    case transportError(reason: String)
    case codecError(reason: String)
    case handshakeError(reason: String)
    case proxyError(reason: String)
    case internalError(reason: String)
    case unknown(reason: String)
}
