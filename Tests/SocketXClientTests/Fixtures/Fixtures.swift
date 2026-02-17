import Foundation
@testable import SocketXClient

/// Centralized fixtures for tests.
enum Fixtures {
    enum URLs {
        static let base = URL(string: "wss://test.socketx.local")!
        static let room = URL(string: "wss://test.socketx.local/room/42")!
    }

    enum Headers {
        static let authSample = ["Authorization": "Bearer test-token"]
        static let contentTypeSample = ["Content-Type": "application/json"]
        static let empty: [String: String] = [:]
    }

    enum Rooms {
        static let roomPath = "/room/42"
        static let roomPathWithQuery = "/room/42?token=test"
    }

    enum Text {
        static let empty = Data("".utf8)
        static let unicode = Data("こんにちは, world — 🚀".utf8)
        static let multiline = Data("line1\nline2\nline3".utf8)
        static let long: Data = {
            String(repeating: "x", count: 4096).data(using: .utf8)!
        }()
    }

    enum Binary {
        static let empty = Data()
        static let small = Data([0,1,2,3,4,5])
        static let large: Data = {
            var bytes = [UInt8](repeating: 0xAA, count: 16 * 1024)
            return Data(bytes)
        }()
    }

    enum Errors {
        static let malformedData = Data([0x00, 0xFF])
        static let emptyData = Data()
        static let missingHeaderData = Data([0x01, 0x02, 0x03])
        static let transportError = NSError(domain: "SocketX.Fixtures", code: 1, userInfo: [NSLocalizedDescriptionKey: "transport"])

        static let socketXNetwork = SocketXError.networkError(reason: "network")
        static let socketXTransport = SocketXError.transportError(reason: "transport")
        static let socketXCodec = SocketXError.codecError(reason: "codec")
        static let socketXHandshake = SocketXError.handshakeError(reason: "handshake")
        static let socketXProxy = SocketXError.proxyError(reason: "proxy")
        static let socketXInternal = SocketXError.internalError(reason: "internal")
        static let socketXUnknown = SocketXError.unknown(reason: "unknown")
    }
}
