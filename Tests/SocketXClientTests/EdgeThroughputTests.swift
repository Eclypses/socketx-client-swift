import XCTest
@testable import SocketXClient

final class EdgeThroughputTests: XCTestCase {

    func testRapidConnectDisconnectLoops() {
        let fake = FakeTransport()

        for _ in 0..<50 {
            fake.connect()
            fake.disconnect()
        }

        XCTAssertEqual(fake.connectCount, 50)
        XCTAssertEqual(fake.disconnectCount, 50)
        XCTAssertFalse(fake.isConnected)
    }

    func testBurstSendsMixedPayloads() {
        let fake = FakeTransport()
        fake.simulateConnected()

        for index in 0..<200 {
            if index % 2 == 0 {
                fake.send(action: .proxyData, messageType: 0, payload: Fixtures.Text.multiline)
            } else {
                fake.send(action: .proxyData, messageType: 1, payload: Fixtures.Binary.small)
            }
        }

        XCTAssertEqual(fake.sendCount, 200)
        XCTAssertEqual(fake.sentTextHistory.count, 100)
        XCTAssertEqual(fake.sentBinaryHistory.count, 100)
    }

    func testEmptyAndLargePayloadHandling() {
        let fake = FakeTransport()
        fake.simulateConnected()

        fake.send(action: .proxyData, messageType: 0, payload: Fixtures.Text.empty)
        fake.send(action: .proxyData, messageType: 0, payload: Fixtures.Text.long)
        fake.send(action: .proxyData, messageType: 1, payload: Fixtures.Binary.empty)
        fake.send(action: .proxyData, messageType: 1, payload: Fixtures.Binary.large)

        XCTAssertEqual(fake.sentTextHistory.first, Fixtures.Text.empty)
        XCTAssertEqual(fake.sentTextHistory.last, Fixtures.Text.long)
        XCTAssertEqual(fake.sentBinaryHistory.first, Fixtures.Binary.empty)
        XCTAssertEqual(fake.sentBinaryHistory.last, Fixtures.Binary.large)
    }
}
