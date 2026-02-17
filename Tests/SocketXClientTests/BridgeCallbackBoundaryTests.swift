import XCTest
@testable import SocketXClient

final class BridgeCallbackBoundaryTests: XCTestCase {

    private final class MessageRelay {
        private var subscribers: [((ActionByte, UInt8, Data) -> Void)] = []

        func subscribe(_ callback: @escaping (ActionByte, UInt8, Data) -> Void) {
            subscribers.append(callback)
        }

        func forward(action: ActionByte, messageType: UInt8, payload: Data) {
            subscribers.forEach { $0(action, messageType, payload) }
        }
    }

    func testHeaderBridgePreservesActionMessageTypeAndPayload() {
        let payload = Fixtures.Binary.small
        let wrapped = Header.wrap(action: .proxyData, messageType: 1, payload: payload)
        let unwrapped = Header.unwrap(wrapped)

        XCTAssertEqual(unwrapped?.0, .proxyData)
        XCTAssertEqual(unwrapped?.1, 1)
        XCTAssertEqual(unwrapped?.2, payload)
    }

    func testInboundCallbacksMaintainOrderingAcrossSubscribers() {
        let fake = FakeTransport()
        let relay = MessageRelay()
        var order: [String] = []

        relay.subscribe { _, _, _ in order.append("sub1") }
        relay.subscribe { _, _, _ in order.append("sub2") }

        fake.onMessage = { action, messageType, payload in
            relay.forward(action: action, messageType: messageType, payload: payload)
        }

        fake.simulateTextMessage(Fixtures.Text.unicode)
        fake.simulateBinaryMessage(Fixtures.Binary.small)

        XCTAssertEqual(order, ["sub1", "sub2", "sub1", "sub2"])
    }
}
