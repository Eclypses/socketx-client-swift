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
import Mte
import Core
import MKE
import Kyber

final class MteCodec: MteEntropyCallback, MteNonceCallback {
    
    var encPersStr: String!
    var decPersStr: String!
    var encKyber: MteKyber!
    var decKyber: MteKyber!
    var encMyPublicKey: [UInt8]!
    var encPeerEncryptedSecret: [UInt8]!
    var decMyPublicKey: [UInt8]!
    var decPeerEncryptedSecret: [UInt8]!
    var encNonce: UInt64!
    var decNonce: UInt64!
    var encoder: MteMkeEnc!
    var decoder: MteMkeDec!
    var pairType: Int!
    
    init() {
        do {
            encPersStr = getRandomString(length: 64)
            decPersStr = getRandomString(length: 64)
            
            encKyber = try MteKyber(strength: KyberStrength.K512)
            let enckeyResult = encKyber.createKeyPair()
            try checkKyberStatus(status: enckeyResult.status)
            encMyPublicKey = enckeyResult.publicKey
            
            decKyber = try MteKyber(strength: KyberStrength.K512)
            let deckeyResult = decKyber.createKeyPair()
            try checkKyberStatus(status: deckeyResult.status)
            decMyPublicKey = deckeyResult.publicKey
        } catch {
            reportError(.codecError(reason: "Failed to initialize MteCodec. Error: \(error)"), self)
        }
    }
    
    func getPairingKeys() -> Data {
        var returnData: Data = Data()
        let pairKeys = PairingRequest(
            encoderPublicKey: self.bytesToB64Str(publicKey: encMyPublicKey),
            encoderPersonalization: encPersStr,
            decoderPublicKey: self.bytesToB64Str(publicKey: decMyPublicKey),
            decoderPersonalization: decPersStr
        )
        do {
            returnData = (try JSONEncoder().encode(pairKeys))
        } catch {
            reportError(.codecError(reason: "Failed to get pairing keys. Error: \(error)"), self)
        }
        return returnData
    }
    
    func completePairing(payload: Data) {
        do {
            let response = try JSONDecoder().decode(PairingResponse.self, from: payload)
            encPeerEncryptedSecret = b64StrToBytes(publicKeyStr: response.decoderSecret)
            encNonce = UInt64(response.decoderNonce)!
            decPeerEncryptedSecret = b64StrToBytes(publicKeyStr: response.encoderSecret)
            decNonce = UInt64(response.encoderNonce)!
            try createEncoderAndDecoder()
        } catch {
            reportError(.codecError(reason: "Failed to complete pairing. Error: \(error)"), self)
        }
    }
    
    func createEncoderAndDecoder() throws {
        try instantiateEncoder()
        try instantiateDecoder()
    }
    
    func instantiateEncoder() throws {
        encoder = try MteMkeEnc()
        pairType = 0
        encoder.setEntropyCallback(self)
        encoder.setNonceCallback(self)
        let status = encoder.instantiate(encPersStr)
        try checkMteStatus(function: #function, status: status)
        // Uncomment to confirm encoder state value and and compare with Server decoder state. This is a particularly useful debugging tool.
//                                print("Encoder initial state: \(encoder.saveStateB64()!)")
    }
    
    func instantiateDecoder() throws {
        decoder = try MteMkeDec()
        pairType = 1
        decoder.setEntropyCallback(self)
        decoder.setNonceCallback(self)
        let status = decoder.instantiate(decPersStr)
        try checkMteStatus(function: #function, status: status)
        // Uncomment to confirm decoder state value and and compare with Server encoder state. This is a particularly useful debugging tool.
//                        debugPrint("Decoder initial state: \(decoder.saveStateB64()!)")
    }
    
    func encode(_ data: Data) -> Data {
        var encoded = Data()
        do {
            let encodeResult = encoder.encode([UInt8](data))
            try checkMteStatus(function: #function, status: encodeResult.status)
            encoded = Data(encodeResult.encoded)
        } catch {
            reportError(.codecError(reason: "Failed to encode Data. Error: \(error)"), self)
        }
        return encoded
    }
    
    func decode(_ data: Data) -> Data {
        var decoded = Data()
        do {
            let decodeResult = decoder.decode([UInt8](data))
            try checkMteStatus(function: #function, status: decodeResult.status)
            decoded = Data(decodeResult.decoded)
        } catch {
            reportError(.codecError(reason: "Failed to decode Data: \(error)"), self)
        }
        return decoded
    }
    
    func checkMteStatus(function: String, status: mte_status) throws {
        if status != mte_status_success {
            throw SocketXError.codecError(reason: "Status: \(MteBase.getStatusName(status)). Description: \(MteBase.getStatusDescription(status))")
        }
    }
    
    func checkKyberStatus(status: Int32) throws {
        if KyberResultCode(status).intValue != KyberResultCode.success.intValue {
            throw SocketXError.internalError(reason: "Failed to get public key from Kyber. Error: \(KyberResultCode(status).stringValue)")
        }
    }
    
    private func bytesToB64Str(publicKey: [UInt8]) -> String {
        return Data(publicKey).base64EncodedString()
    }
    
    private func b64StrToBytes(publicKeyStr: String) -> [UInt8] {
        guard let pkData = Data(base64Encoded: publicKeyStr) else {
            reportError(.codecError(reason: "Unable to convert public key to Data"), self)
            return [UInt8]()
        }
        return [UInt8](pkData)
    }
    
    func entropyCallback(_ minEntropy: Int,
                         _ minLength: Int,
                         _ maxLength: UInt64,
                         _ entropyInput: inout [UInt8],
                         _ eiBytes: inout UInt64,
                         _ entropyLong: inout UnsafeMutableRawPointer?) -> mte_status {
        if minLength == 0 && maxLength == 0 {
            entropyInput = []
            debugLog("--------------------------------------\nMTE Trial Build Detected! It offers no Security guarantees. Do not run this in Production!\n--------------------------------------", self)
            
        } else {
            do {
                switch pairType {
                case 1:
                    var decDecryptSecretResult = decKyber.decryptSecret(encryptedSecret: &decPeerEncryptedSecret)
                    try checkKyberStatus(status: decDecryptSecretResult.status)
                    if decDecryptSecretResult.secret.count < minLength || decDecryptSecretResult.secret.count > maxLength {
                        throw "mte_status_drbg_catastrophic"
                    }
                    entropyInput = decDecryptSecretResult.secret
                    decDecryptSecretResult.secret.resetBytes(in: 0..<decDecryptSecretResult.secret.count)
                default:
                    var encDecryptSecretResult = encKyber.decryptSecret(encryptedSecret: &encPeerEncryptedSecret)
                    try checkKyberStatus(status: encDecryptSecretResult.status)
                    if encDecryptSecretResult.secret.count < minLength || encDecryptSecretResult.secret.count > maxLength {
                        throw "mte_status_drbg_catastrophic"
                    }
                    entropyInput = encDecryptSecretResult.secret
                    encDecryptSecretResult.secret.resetBytes(in: 0..<encDecryptSecretResult.secret.count)
                }
            } catch {
                return mte_status_drbg_catastrophic
            }
        }
        return mte_status_success
    }
    
    func nonceCallback(_ minLength: Int, _ maxLength: Int, _ nonce: inout [UInt8], _ nBytes: inout Int) {
        var nCopied: Int = 0
        switch pairType {
        case 1:
            nCopied = min(nonce.count, MemoryLayout.size(ofValue: decNonce))
            for i in 0..<nCopied {
                nonce[i] = UInt8(UInt64(decNonce >> (i * 8)) & 0xFF)
            }
            decNonce = 0
        default:
            nCopied = min(nonce.count, MemoryLayout.size(ofValue: encNonce))
            for i in 0..<nCopied {
                nonce[i] = UInt8(UInt64(encNonce >> (i * 8)) & 0xFF)
            }
            encNonce = 0
        }
        if nCopied < minLength {
            for i in nCopied..<minLength {
                nonce[i] = 0
            }
            nBytes = minLength
        }
        else {
            nBytes = nCopied
        }
    }
}
