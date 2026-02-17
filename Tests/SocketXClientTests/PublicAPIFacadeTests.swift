import XCTest
@testable import SocketXClient

final class PublicAPIFacadeTests: XCTestCase {

    func testConnectSendDisconnectDelegatesToManager() {
        let manager = FakeManager()
        let client = SocketXClient(manager: manager)

        client.connect()
        client.send(text: "hello")
        client.send(binary: Fixtures.Binary.small)
        client.disconnect()

        XCTAssertEqual(manager.connectCount, 1)
        XCTAssertEqual(manager.disconnectCount, 1)
        XCTAssertEqual(manager.sendTextHistory, ["hello"])
        XCTAssertEqual(manager.sendBinaryHistory, [Fixtures.Binary.small])
    }

    func testManagerCallbacksAreForwardedToPublicCallbacks() {
        let manager = FakeManager()
        let client = SocketXClient(manager: manager)

        let connected = expectation(description: "connected")
        let text = expectation(description: "text")
        let binary = expectation(description: "binary")

        client.onConnected = { connected.fulfill() }
        client.onMessageReceived = { message in
            XCTAssertEqual(message, "hi")
            text.fulfill()
        }
        client.onBinaryReceived = { payload in
            XCTAssertEqual(payload, Fixtures.Binary.small)
            binary.fulfill()
        }

        manager.simulatePaired()
        manager.simulateText("hi")
        manager.simulateBinary(Fixtures.Binary.small)

        waitForExpectations(timeout: 1.0)
    }

    func testReportErrorPropagatesToClientOnError() {
        let manager = FakeManager()
        let client = SocketXClient(manager: manager)
        let errorExpectation = expectation(description: "onError")

        client.onError = { error in
            if case let .transportError(reason) = error {
                XCTAssertEqual(reason, "boom")
                errorExpectation.fulfill()
            }
        }

        reportError(.transportError(reason: "boom"), self)
        waitForExpectations(timeout: 1.0)
    }
}
