# SocketXClient Testing Summary

## Purpose
This test suite is designed for an iOS-only package and is intended to catch regressions quickly in:
- SocketX protocol/header behavior
- callback/bridge boundaries
- facade delegation and error propagation
- fake-based transport workflows and throughput edges

## Layered test architecture
1. **Test infrastructure fake(s)**
   - `FakeTransport` with failure toggles, call counters, arg capture, ordered histories, event simulation, reset/dispose.
   - `FakeManager` for deterministic `SocketXClient` facade delegation tests.

2. **Centralized fixtures**
   - Shared URLs, room paths, headers, text payloads, binary payloads, malformed payloads, and error fixtures.

3. **Error/model parsing tests**
   - Header unwrap malformed behavior and unknown action fallback.
   - Codable model missing-key decoding failures.
   - `SocketXError` description mapping.
   - `KyberResultCode` unknown/custom fallback.

4. **Protocol/contract tests**
   - `Transportable` default `send(action:payload:)` contract (`messageType = 254`).
   - fake transport conformance smoke test.

5. **Bridge/callback boundary tests**
   - Header wrap/unwrap boundary checks.
   - inbound callback ordering and multi-subscriber fan-out behavior.

6. **Public API/facade tests**
   - `SocketXClient` delegates to manager for connect/send/disconnect.
   - callback forwarding from manager to public closures.
   - centralized `reportError` propagation to `onError`.

7. **Edge/throughput scenarios**
   - rapid connect/disconnect loops
   - burst sends (mixed text/binary)
   - empty and large payload handling

## Test execution (local)
Run package tests using Xcode’s iOS simulator test runner:

```bash
xcodebuild -list
xcodebuild -showdestinations -scheme SocketXClient
xcodebuild test \
   -scheme SocketXClient \
   -destination "platform=iOS Simulator,name=iPhone 15,OS=17.5"
```

## CI guidance (Azure Intel Mac)
Pipeline should use `xcodebuild test` with iOS simulator destination (not `swift test`) because this package links an iOS-only MTE XCFramework.

- `develop` branch: run simulator tests.
- PRs targeting `master`: run simulator tests.
- `master` branch: run simulator tests with coverage enabled and enforce `coverageThreshold` from `azure-pipelines.yml` (currently `70`).

## Baseline test count / coverage
- Baseline XCTest count added in this pass: **24 tests**.
- Coverage is enabled and gated on `master` in CI (`-enableCodeCoverage YES` + `xccov` threshold check).

## Reusable patterns
- Prefer fake/stub hand-written test doubles over runtime mocking.
- Keep async assertions bounded with XCTest expectations and short timeouts.
- Use fixture constants for all payloads/URLs/error inputs to avoid inline literals.
- Test observable contracts (arguments, callbacks, ordering), not private implementation internals.
