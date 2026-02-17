# SocketX Mobile Client - Swift Package Context

## 1. Project Overview
This project (`socketx-client-swift`) is a Swift SPM package that provides a secure WebSocket client for **Eclypses SocketX**, enabling iOS applications to establish encrypted, persistent connections to a SocketX server for relaying application data with end-to-end MTE encryption.

**Primary Goal:** To provide iOS developers with a secure WebSocket client that handles MTE encryption/decryption transparently, allowing applications to send and receive data through a SocketX server tunnel with automatic pairing and key management.

## 2. Intended Use
This library is designed for iOS developers (iOS 14+) who need to secure WebSocket communication with a SocketX server using dependency injection for network configuration.

*   **Supported Stack:** URLSessionWebSocketTask (native iOS WebSocket support).
*   **Core Features:**
    *   Dependency injection pattern for custom URLSession configuration.
    *   Automatic MTE pairing using post-quantum Kyber key exchange.
    *   Transparent encryption of outgoing messages and decryption of incoming messages.
    *   Support for both text and binary message types.
    *   Event-based callbacks (onConnected, onMessageReceived, onBinaryReceived, onError).
    *   Licensed MTE encryption (requires Eclypses license).

## 3. Core Architecture
The library uses a layered architecture with separation of concerns: SocketXClient (public API) → Manager (orchestration) → Transport (WebSocket) + MteCodec (encryption).

### A. `SocketXClient` (Main Entry Point)
*   **Role**: The primary public interface for the app.
*   **Responsibility**:
    *   Initializes MTE licensing and validates settings.
    *   Accepts a pre-configured URLSessionWebSocketTask via dependency injection.
    *   Provides simple methods: `connect()`, `disconnect()`, `send(text:)`, `send(binary:)`.
    *   Exposes callbacks: `onConnected`, `onMessageReceived`, `onBinaryReceived`, `onError`.

### B. `Manager`
*   **Role**: Orchestrates the pairing handshake and message routing.
*   **Responsibility**:
    *   Manages pairing state machine (unpaired → sentHello → awaitingPairResponse → sentEncryptedPath → paired).
    *   Extracts room path from the WebSocket task's URL.
    *   Coordinates handshake protocol with the SocketX server.
    *   Routes proxy data through MteCodec for encryption/decryption.
    *   Dispatches received messages to SocketXClient callbacks.

### C. `Transport`
*   **Role**: WebSocket communication layer implementing the `Transportable` protocol.
*   **Responsibility**:
    *   Wraps the injected URLSessionWebSocketTask.
    *   Manages connection lifecycle (resume, cancel).
    *   Sends/receives binary WebSocket frames.
    *   Wraps/unwraps SocketX protocol headers (7-byte header format).
    *   Provides recursive receive loop for incoming messages.

### D. `MteCodec`
*   **Role**: MTE encryption/decryption and Kyber key exchange.
*   **Responsibility**:
    *   Generates Kyber-512 keypairs for encoder and decoder.
    *   Creates personalization strings for MTE instances.
    *   Builds pairing request payloads (JSON with public keys).
    *   Completes pairing with server response (encrypted secrets and nonces).
    *   Instantiates MteMkeEnc and MteMkeDec for message encryption/decryption.
    *   Implements MteEntropyCallback and MteNonceCallback.

### E. `Header`
*   **Role**: Protocol header management.
*   **Responsibility**:
    *   Defines ActionByte enum (request, response, pairRequest, pairResponse, etc.).
    *   Wraps messages with 7-byte header: [77,84,69,2] (protocol) + version + action + messageType + payload.
    *   Unwraps incoming messages and validates protocol/version.

### F. Supporting Components
*   **Models**: `PairingRequest`, `PairingResponse` (Codable structs for handshake).
*   **Protocols**: `Transportable` (abstraction for WebSocket layer).
*   **Helpers**: `GeneralHelpers.swift` (utility functions).
*   **Extensions**: Additional Swift extensions for common operations.
*   **Settings**: Actor-based configuration (version, license keys).

## 4. Data Flow

### Initial Connection & Pairing Sequence
1. **App Setup**: App creates URLSessionWebSocketTask with custom URLSession (headers, auth, etc.).
2. **Initialization**: App instantiates `SocketXClient(task:)`, which validates MTE license and stores task.
3. **Connect**: App calls `client.connect()`, which triggers `manager.connect()`.
4. **WebSocket Open**: Manager polls Transport until `isConnected` is true.
5. **Handshake**: Manager sends "Hello" (action=0), receives response (action=1).
6. **Kyber Pairing**: Manager sends pairing request (action=2) with Kyber public keys and personalization strings.
7. **Pair Response**: Server responds (action=3) with encrypted secrets and nonces.
8. **MTE Instantiation**: Codec creates encoder/decoder with Kyber-derived secrets.
9. **Room Connection**: Manager encrypts room path and sends upstream connection request (action=4).
10. **Connected**: Server confirms (action=5), Manager sets state to `.paired` and triggers `onConnected` callback.

### Message Send/Receive
1. **Send**: App calls `client.send(text:)` or `client.send(binary:)`.
2. **Encode**: Manager encodes payload with MteCodec and wraps with proxyData header (action=6).
3. **Transmit**: Transport sends binary WebSocket frame.
4. **Receive**: Transport receives frame, unwraps header.
5. **Decode**: Manager decodes payload with MteCodec.
6. **Callback**: Manager dispatches to `onMessageReceived` or `onBinaryReceived` on main queue.

## 5. Key File Structure
*   **`SocketXClient/SocketXClient.swift`**: Main public API class.
*   **`SocketXClient/Manager.swift`**: Pairing state machine and message orchestration.
*   **`SocketXClient/Transport.swift`**: WebSocket layer (URLSessionWebSocketTask wrapper).
*   **`SocketXClient/MteCodec.swift`**: MTE encryption/decryption and Kyber key exchange.
*   **`SocketXClient/Header.swift`**: Protocol header wrapping/unwrapping.
*   **`SocketXClient/Settings.swift`**: Version and license configuration.
*   **`SocketXClient/Extensions.swift`**: Swift extensions.
*   **`SocketXClient/Models/`**: PairingRequest, PairingResponse.
*   **`SocketXClient/Protocols/`**: Transportable protocol.
*   **`SocketXClient/Helpers/`**: GeneralHelpers utility functions.
*   **`Core/`**: MTE base wrappers (MteBase, MteEnc, MteDec, MteRandom).
*   **`MKE/`**: MTE MKE wrappers (MteMkeEnc, MteMkeDec).
*   **`Kyber/`**: Kyber key exchange wrapper (MteKyber).
*   **`Mte/`**: Native MTE C library headers and xcframework binary.
*   **`Package.swift`**: SPM manifest defining targets and dependencies.

## 6. Configuration
Configuration is minimal and handled via dependency injection:
*   **`Settings.swift`**: Contains version (2.0.0), MTE license keys (hardcoded for Eclypses).
*   **URLSession**: App provides custom URLSession configuration (headers, certificates, etc.).
*   **WebSocket URL**: Room path is extracted from the task's URL (path + query).
*   **Callbacks**: App sets `onConnected`, `onMessageReceived`, `onBinaryReceived`, `onError` closures.

## 7. Testing & CI Notes
The package is **iOS-only** and links an iOS-only MTE XCFramework. Because of this:
* Use `xcodebuild test` with an **iOS Simulator** destination for local and CI test runs.
* Do **not** rely on plain `swift test` on macOS host defaults for validation.

Baseline layered tests are organized in `Tests/SocketXClientTests/` and include:
* fake infrastructure (`FakeTransport`, `FakeManager`)
* centralized fixtures
* model/error tests
* protocol contract tests
* bridge callback boundary tests
* facade/public API delegation tests
* edge/throughput scenario tests

See `dev_docs/TESTING_SUMMARY.md` for commands and suite details.

---
This document provides concise technical context for the iOS SocketX Client library. For API usage examples, see README.md.
