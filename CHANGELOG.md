# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [2.0.0] - 2025-12-23

### Added
    - Support for Dependency Injection via `init(task: URLSessionWebSocketTask)`.
    - Added `release.sh` script to automate versioning, tagging, and changelog updates.

### Changed
    - Refactored `SocketXClient` to accept an existing `URLSessionWebSocketTask`, allowing for custom `URLSession` configurations (headers, pinning, etc).
    - Updated `Manager` room path extraction logic to use `URLComponents` for better robustness.
    - Updated `README.md` to reflect new initialization pattern.

### Removed
    - `init(url: String)` initializer (Breaking Change).



## [1.0.1] - 2025-11-12

### Added
    README.md and CHANGELOG.md

### Changed
    - Cleaned up comments
    - Bumped Version to 1.0.1
    
### Fixed
    - Updated pipeline.yaml to reference correct repo 



## [1.0.0] - 2025-9-24

### Added
    Initial commit

### Changed
    
### Fixed



[2.0.0]: https://github.com/Eclypses/socketx-client-swift/releases/tag/v2.0.0
