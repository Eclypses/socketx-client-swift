import XCTest
@testable import SocketXClient
import Kyber

final class ModelAndErrorTests: XCTestCase {

    func testHeaderUnwrapUnknownActionFallsBackToUnknown() {
        let payload = Fixtures.Text.unicode
        let wrapped = Header.wrap(action: .proxyData, messageType: 1, payload: payload)
        var mutated = wrapped
        mutated[5] = 250

        let unwrapped = Header.unwrap(mutated)
        XCTAssertNotNil(unwrapped)
        XCTAssertEqual(unwrapped?.0, .unknown)
        XCTAssertEqual(unwrapped?.1, 1)
        XCTAssertEqual(unwrapped?.2, payload)
    }

    func testHeaderUnwrapMalformedDataReturnsNil() {
        XCTAssertNil(Header.unwrap(Fixtures.Errors.malformedData))
        XCTAssertNil(Header.unwrap(Fixtures.Errors.emptyData))
        XCTAssertNil(Header.unwrap(Fixtures.Errors.missingHeaderData))
    }

    func testPairingRequestDecodingMissingKeysThrows() {
        let json = "{\"encoderPublicKey\":\"a\"}"
        let data = Data(json.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(PairingRequest.self, from: data))
    }

    func testPairingResponseDecodingMissingKeysThrows() {
        let json = "{\"encoderSecret\":\"a\",\"encoderNonce\":\"b\"}"
        let data = Data(json.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(PairingResponse.self, from: data))
    }

    func testSocketXErrorDescriptionIncludesCategoryAndReason() {
        XCTAssertEqual(Fixtures.Errors.socketXNetwork.description, "Network error: network")
        XCTAssertEqual(Fixtures.Errors.socketXTransport.description, "Transport error: transport")
        XCTAssertEqual(Fixtures.Errors.socketXCodec.description, "Codec error: codec")
        XCTAssertEqual(Fixtures.Errors.socketXHandshake.description, "Handshake error: handshake")
        XCTAssertEqual(Fixtures.Errors.socketXProxy.description, "Proxy error: proxy")
        XCTAssertEqual(Fixtures.Errors.socketXInternal.description, "Internal error: internal")
        XCTAssertEqual(Fixtures.Errors.socketXUnknown.description, "Unknown error: unknown")
    }

    func testKyberResultCodeUnknownValueFallsBackToCustom() {
        let code = KyberResultCode(1234)
        XCTAssertEqual(code.stringValue, "1234")
    }
}
