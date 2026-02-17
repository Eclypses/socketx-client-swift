import Foundation
@testable import SocketXClient

/// Test fake implementing `Transportable` for deterministic tests.
final class FakeTransport: Transportable {

    // MARK: - Callbacks
    var onMessage: ((ActionByte, UInt8, Data) -> Void)?
    var onError: ((SocketXError) -> Void)?

    // MARK: - State
    private(set) var isConnected = false

    // MARK: - Failure toggles
    var failConnect = false
    var failDisconnect = false
    var failSendText = false
    var failSendBinary = false

    // MARK: - Counters / captures
    private(set) var connectCount = 0
    private(set) var disconnectCount = 0
    private(set) var sendCount = 0

    private(set) var lastSendAction: ActionByte?
    private(set) var lastSendMessageType: UInt8?
    private(set) var lastSendPayload: Data?

    // Ordered histories
    private(set) var sentTextHistory: [Data] = []
    private(set) var sentBinaryHistory: [Data] = []
    private(set) var sendHistory: [(action: ActionByte, messageType: UInt8, payload: Data)] = []

    // MARK: - Lifecycle
    func connect() {
        connectCount += 1
        if failConnect {
            isConnected = false
            onError?(.transportError(reason: "connect failed"))
            return
        }
        isConnected = true
    }

    func disconnect() {
        disconnectCount += 1
        if failDisconnect {
            onError?(.transportError(reason: "disconnect failed"))
            return
        }
        isConnected = false
    }

    func send(action: ActionByte, messageType: UInt8, payload: Data) {
        sendCount += 1
        lastSendAction = action
        lastSendMessageType = messageType
        lastSendPayload = payload
        sendHistory.append((action, messageType, payload))

        // Treat messageType 0 as text for testing conveniences, otherwise binary
        if messageType == 0 {
            if failSendText {
                onError?(.transportError(reason: "send text failed"))
                return
            }
            sentTextHistory.append(payload)
        } else {
            if failSendBinary {
                onError?(.transportError(reason: "send binary failed"))
                return
            }
            sentBinaryHistory.append(payload)
        }
    }

    // MARK: - Helpers / Simulators
    /// Simulate an inbound headered message arriving from the network.
    func simulateMessage(action: ActionByte, messageType: UInt8, payload: Data) {
        onMessage?(action, messageType, payload)
    }

    func simulateTextMessage(_ payload: Data) {
        onMessage?(.proxyData, 0, payload)
    }

    func simulateBinaryMessage(_ payload: Data) {
        onMessage?(.proxyData, 1, payload)
    }

    func simulateError(_ error: SocketXError) {
        onError?(error)
    }

    /// Simulate connected state change (useful when other components expect a connect event)
    func simulateConnected() {
        isConnected = true
    }

    /// Simulate disconnect / remote close
    func simulateDisconnected() {
        isConnected = false
    }

    /// Reset counters and history
    func reset() {
        isConnected = false
        failConnect = false
        failDisconnect = false
        failSendText = false
        failSendBinary = false

        connectCount = 0
        disconnectCount = 0
        sendCount = 0

        lastSendAction = nil
        lastSendMessageType = nil
        lastSendPayload = nil

        sentTextHistory.removeAll()
        sentBinaryHistory.removeAll()
        sendHistory.removeAll()
    }

    /// Dispose handlers
    func dispose() {
        onMessage = nil
        onError = nil
        reset()
    }
}
