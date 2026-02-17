import XCTest
@testable import SocketXClient

final class TransportContractTests: XCTestCase {

    private final class SpyTransport: Transportable {
        var onMessage: ((ActionByte, UInt8, Data) -> Void)?
        private(set) var captured: (ActionByte, UInt8, Data)?

        func send(action: ActionByte, messageType: UInt8, payload: Data) {
            captured = (action, messageType, payload)
        }

        func connect() {}
        func disconnect() {}
    }

    func testTransportableConvenienceSendUsesDefaultMessageType() {
        let transport = SpyTransport()
        transport.send(action: .request, payload: Fixtures.Text.multiline)

        XCTAssertEqual(transport.captured?.0, .request)
        XCTAssertEqual(transport.captured?.1, 254)
        XCTAssertEqual(transport.captured?.2, Fixtures.Text.multiline)
    }

    func testFakeTransportConformsToTransportableContract() {
        let transport: any Transportable = FakeTransport()
        transport.connect()
        transport.send(action: .response, messageType: 254, payload: Fixtures.Text.empty)
        transport.disconnect()
    }
}
