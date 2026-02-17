import Foundation
@testable import SocketXClient

final class FakeManager: Managing {
    var onPaired: (() -> Void)?
    var onMessageReceived: ((String) -> Void)?
    var onBinaryReceived: ((Data) -> Void)?

    private(set) var connectCount = 0
    private(set) var disconnectCount = 0
    private(set) var sendTextHistory: [String] = []
    private(set) var sendBinaryHistory: [Data] = []

    func connect() {
        connectCount += 1
    }

    func disconnect() {
        disconnectCount += 1
    }

    func sendProxyData(text: String) {
        sendTextHistory.append(text)
    }

    func sendProxyData(binary data: Data) {
        sendBinaryHistory.append(data)
    }

    func simulatePaired() {
        onPaired?()
    }

    func simulateText(_ text: String) {
        onMessageReceived?(text)
    }

    func simulateBinary(_ data: Data) {
        onBinaryReceived?(data)
    }
}
