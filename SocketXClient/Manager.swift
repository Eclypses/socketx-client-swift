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
import Kyber

final class Manager {
    
    // MARK: - Types
    enum PairingState {
        case unpaired
        case sentHello
        case awaitingPairResponse
        case sentEncryptedPath
        case paired
    }
    
    enum MessageType: UInt8 {
        case text = 0
        case binary = 1
    }
    
    // MARK: Class Variables
    private var transport: Transportable
    private let codec: MteCodec
    private var roomPath: String = ""
    
    private var pairingState: PairingState = .unpaired
    
    // MARK: Callbacks
    var onPaired: (() -> Void)?
    var onMessageReceived: ((String) -> Void)?
    var onBinaryReceived: ((Data) -> Void)?
    
    init(urlString: String) {
        
        
        // extract roomPath, if any, and store in roomPath variable for later use.
        let (baseUrlString, roomPath) = Self.captureRoomPath(urlString)
        self.roomPath = roomPath
        
        self.transport = Transport(urlString: baseUrlString)
        self.codec = MteCodec()
        
        // Wire transport messages through codec / handshake
        self.transport.onMessage = { [weak self] action, messageType, payload in
            guard let self = self else { return }
            
            switch action {
            case .proxyData:
                self.handleProxyData(payload: payload, messageType: messageType)
            case .request, .response, .pairRequest,
                    .pairResponse, .upstreamConnectionRequest,
                    .upstreamConnectionResponse:
                self.handleHandshake(action: action, payload: payload)
            default:
                reportError(.internalError(reason: "Unexpected action: \(action)"), self)
            }
        }
    }
    
    /// Splits the base websocket URL and extracts the optional room path.
    /// Returns (baseUrlString, roomPath)
    static func captureRoomPath(_ urlString: String) -> (String, String) {
        let basePath = "/ws"
        
        guard let wsRange = urlString.range(of: basePath) else {
            return (urlString, "")
        }
        
        let afterWs = urlString[wsRange.upperBound...]
        let roomPath = afterWs.isEmpty ? "" : String(afterWs)
        let baseUrlString = String(urlString[..<wsRange.upperBound])
        
        return (baseUrlString, roomPath)
    }
    
    // MARK: - Connection
    func connect() {
        transport.connect()
        
        // wait for transport to be ready, then start handshake
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // Poll for WebSocketTransport's isConnected (simple and reliable)
            while !(self.transport as? Transport)!.isConnected {
                usleep(50_000) // 50ms
            }
            
            DispatchQueue.main.async {
                self.sendHello()
            }
        }
    }
    
    func disconnect() {
        transport.disconnect()
        pairingState = .unpaired
    }
    
    // MARK: - Proxy send (app-facing)
    func sendProxyData(text: String) {
        let data = Data(text.utf8)
        sendProxyData(data, messageType: .text)
    }
    
    func sendProxyData(binary data: Data) {
        sendProxyData(data, messageType: .binary)
    }
    
    private func sendProxyData(_ data: Data, messageType: MessageType) {
        let encoded = codec.encode(data)
        transport.send(action: .proxyData, messageType: messageType.rawValue, payload: encoded)
    }
    
    // MARK: - Proxy receive
    private func handleProxyData(payload: Data, messageType: UInt8) {
        let decoded = codec.decode(payload)
        
        guard let type = MessageType(rawValue: messageType) else {
            reportError(.networkError(reason: "Unknown message type: \(messageType)"), self)
            return
        }
        
        switch type {
        case .text:
            if let text = String(data: decoded, encoding: .utf8) {
                onMessageReceived?(text)
            }
        case .binary:
            onBinaryReceived?(decoded)
        }
    }
    
    // MARK: - Handshake / Pairing
    private func sendHello() {
        transport.send(action: .request, messageType: 254, payload: Data())
        pairingState = .sentHello
        debugLog("→ Sent hello (action=0)", self, function: #function)
    }
    
    private func handleHandshake(action: ActionByte, payload: Data) {
        switch (pairingState, action) {
        case (.sentHello, .response):
            debugLog("← Received ack (action=1)", self, function: #function)
            initiateKyberPairing()
            
        case (.awaitingPairResponse, .pairResponse):
            debugLog("← Received pair response (action=3)", self, function : #function)
            handlePairResponsePayload(payload)
            
        case (.sentEncryptedPath, .upstreamConnectionResponse):
            debugLog("← Received upstream connection response (action=5) — paired", self, function : #function)
            pairingState = .paired
            onPaired?()
            
        default:
            reportError(.handshakeError(reason: "Unexpected handshake message: state=\(pairingState), action=\(action)"), self)
        }
    }
    
    // MARK: - KYBER + Pairing helpers
    
    private func initiateKyberPairing() {
        sendSafe(action: .pairRequest, messageType: 254) { [weak self] in
            let payload = self?.codec.getPairingKeys()
            
            self?.pairingState = .awaitingPairResponse
            debugLog("→ Sent pair request (action=2)", self, function : #function)
            return payload ?? Data()
        }
    }
    
    private func handlePairResponsePayload(_ payload: Data) {
        do {
            codec.completePairing(payload: payload)
            
            try sendEncryptedRoomPath()
        } catch {
            reportError(.handshakeError(reason: "Failed to process pairResponse (action=3)"), self)
        }
    }
    
    private func sendEncryptedRoomPath() throws {
        do {
            let pathnameData = try JSONSerialization.data(withJSONObject: ["pathname": roomPath])
            let payload = codec.encode(pathnameData)
            transport.send(action: .upstreamConnectionRequest, messageType: 254, payload: payload)
            pairingState = .sentEncryptedPath
            debugLog("→ Sent encrypted room path (action=4)", self)
        } catch {
            throw error
        }
    }
    
    // MARK: - Helpers
    
    private func sendSafe(action: ActionByte, messageType: UInt8, payloadProvider: () throws -> Data) {
        do {
            let payload = try payloadProvider()
            transport.send(action: action, messageType: messageType, payload: payload)
        } catch {
            reportError(.handshakeError(reason: "Failed to prepare/send payload for action=\(action)"), self)
        }
    }
    
}


