import XCTest
@testable import SocketXClient

final class FakeTransportTests: XCTestCase {

    func testConnectSucceedsWhenNotToggled() {
        let fake = FakeTransport()
        XCTAssertFalse(fake.isConnected)
        fake.connect()
        XCTAssertTrue(fake.isConnected)
        XCTAssertEqual(fake.connectCount, 1)
    }

    func testConnectFailsWhenToggled() {
        let fake = FakeTransport()
        fake.failConnect = true
        fake.connect()
        XCTAssertFalse(fake.isConnected)
        XCTAssertEqual(fake.connectCount, 1)
    }

    func testSendCapturesHistoryAndLastArgs_text() {
        let fake = FakeTransport()
        fake.simulateConnected()
        let payload = Fixtures.Text.unicode
        fake.send(action: .proxyData, messageType: 0, payload: payload)

        XCTAssertEqual(fake.sendCount, 1)
        XCTAssertEqual(fake.lastSendAction, .proxyData)
        XCTAssertEqual(fake.lastSendMessageType, 0)
        XCTAssertEqual(fake.lastSendPayload, payload)
        XCTAssertEqual(fake.sentTextHistory.count, 1)
        XCTAssertEqual(fake.sendHistory.count, 1)
    }

    func testSendCapturesHistoryAndLastArgs_binary() {
        let fake = FakeTransport()
        fake.simulateConnected()
        let payload = Fixtures.Binary.small
        fake.send(action: .proxyData, messageType: 1, payload: payload)

        XCTAssertEqual(fake.sendCount, 1)
        XCTAssertEqual(fake.lastSendMessageType, 1)
        XCTAssertEqual(fake.sentBinaryHistory.count, 1)
    }

    func testSimulateMessageInvokesOnMessage() {
        let fake = FakeTransport()
        let expect = expectation(description: "onMessage called")
        fake.onMessage = { action, messageType, data in
            XCTAssertEqual(action, .proxyData)
            XCTAssertEqual(messageType, 0)
            XCTAssertEqual(data, Fixtures.Text.multiline)
            expect.fulfill()
        }

        fake.simulateMessage(action: .proxyData, messageType: 0, payload: Fixtures.Text.multiline)
        waitForExpectations(timeout: 1)
    }

    func testResetClearsState() {
        let fake = FakeTransport()
        fake.simulateConnected()
        fake.send(action: .proxyData, messageType: 0, payload: Fixtures.Text.empty)
        XCTAssertEqual(fake.sendCount, 1)
        fake.reset()
        XCTAssertEqual(fake.sendCount, 0)
        XCTAssertFalse(fake.isConnected)
        XCTAssertTrue(fake.sendHistory.isEmpty)
    }

    func testFailureTogglesEmitErrors() {
        let fake = FakeTransport()
        var errors: [SocketXError] = []
        fake.onError = { errors.append($0) }

        fake.failConnect = true
        fake.connect()

        fake.failDisconnect = true
        fake.disconnect()

        fake.failSendText = true
        fake.send(action: .proxyData, messageType: 0, payload: Fixtures.Text.unicode)

        fake.failSendBinary = true
        fake.send(action: .proxyData, messageType: 1, payload: Fixtures.Binary.small)

        XCTAssertEqual(errors.count, 4)
    }

    func testDisposeClearsCallbacks() {
        let fake = FakeTransport()
        fake.onMessage = { _, _, _ in XCTFail("Expected callback to be removed") }
        fake.onError = { _ in XCTFail("Expected callback to be removed") }

        fake.dispose()

        fake.simulateMessage(action: .proxyData, messageType: 0, payload: Fixtures.Text.empty)
        fake.simulateError(.unknown(reason: "test"))
        XCTAssertNil(fake.onMessage)
        XCTAssertNil(fake.onError)
    }
}
