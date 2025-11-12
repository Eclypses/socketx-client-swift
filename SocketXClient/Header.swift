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

/// Action byte values used internally for SocketXClient messages.
/// (5th byte in the 7-byte header)
enum ActionByte: UInt8 {
    case request = 0
    case response = 1
    case pairRequest = 2
    case pairResponse = 3
    case upstreamConnectionRequest = 4
    case upstreamConnectionResponse = 5
    case proxyData = 6
    case unknown = 255
}

/// Internal struct for handling the fixed 7-byte SocketXClient header.
struct Header {
    static let protocolHeader: [UInt8] = [77, 84, 69, 2]
    static let version: UInt8 = 1

    /// Builds a full message with header + payload.
    static func wrap(
        action: ActionByte,
        messageType: UInt8 = 254, // Default for non-proxy messages
        payload: Data = Data()
    ) -> Data {
        var message = Data()
        message.append(contentsOf: protocolHeader)
        message.append(version)
        message.append(action.rawValue)
        message.append(messageType)
        message.append(payload)
        return message
    }

    static func unwrap(_ data: Data) -> (ActionByte, UInt8, Data)? {
        // Need at least 7 bytes for header
        guard data.count >= protocolHeader.count + 3 else { return nil }
        guard data.prefix(protocolHeader.count) == Data(protocolHeader) else { return nil }

        // Extract fields
        let version = data[protocolHeader.count]
        let actionByte = data[protocolHeader.count + 1]
        let messageType = data[protocolHeader.count + 2]
        let payload = data.dropFirst(protocolHeader.count + 3)

        // Verify version
        guard version == version else {
            reportError(.transportError(reason: "Version mismatch in header: got \(version), expected \(Self.version)"), self)
            return nil
        }

        return (ActionByte(rawValue: actionByte) ?? .unknown, messageType, payload)
    }
}
