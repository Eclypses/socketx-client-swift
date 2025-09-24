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

/// Internal protocol defining a transport capable of sending/receiving headered messages.
protocol Transportable {
    /// Sends a message with the given ActionByte, payload, and messageType (text/binary).
    /// Header bytes are automatically prepended by the implementation.
    func send(action: ActionByte, messageType: UInt8, payload: Data)

    /// Establishes the underlying connection.
    func connect()

    /// Closes the underlying connection.
    func disconnect()

    /// Callback invoked when a headered message is received.
    /// action: the ActionByte
    /// messageType: the 4th header byte (indicates original payload type)
    /// payload: the actual Data payload
    var onMessage: ((ActionByte, UInt8, Data) -> Void)? { get set }
}

// MARK: - Convenience overload
extension Transportable {
    /// Convenience method to send a message with default messageType = 254 (for non-proxy messages)
    func send(action: ActionByte, payload: Data) {
        send(action: action, messageType: 254, payload: payload)
    }
}
