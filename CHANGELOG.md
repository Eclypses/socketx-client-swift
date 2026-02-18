# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
-

### Changed
- 

### Fixed
- Edited release script to run if local is ahead but still block if local is behind remote.


## [2.1.3] - 2026-02-17

### Added
- Added `release.sh` git preflight safeguards to require a clean, synced `develop` before releasing.

### Changed
- Updated `release.sh` post-release push guidance to `git push origin develop $TAG_VERSION`.

### Fixed
- Hardened Azure coverage parsing in `azure-pipelines.yml` to handle differing `xccov` output formats and avoid false CI failures on `master` merges.
- Prevented release-time branch divergence by blocking release runs when local `develop` is ahead/behind/diverged from `origin/develop`.
- Added `release.sh` checks to fail on existing local/remote release tags before tagging.


## [2.1.2] - 2026-02-17

### Added
- Added pipeline YAML lint step to fail fast on formatting/indentation errors in `azure-pipelines.yml`.

### Changed
- Reworked CI test flow for iOS-only validation: simulator tests on `develop`/PRs and coverage-gated simulator tests on `master`.

### Fixed
- Removed `@retroactive` from `String` LocalizedError conformance for Azure Swift toolchain compatibility.
- Corrected `azure-pipelines.yml` indentation/formatting issues that caused Azure YAML parse failures.


## [2.1.1] - 2026-02-17

### Added
-

### Changed
-

### Fixed
- Corrected formatting in azure-pipelines.yml


## [2.1.0] - 2026-02-17

### Added
- Added testing suite with required coverage on merge to master

### Changed
- 

### Fixed
-


## [2.0.2] - 2026-01-20

### Added
- 

### Changed
- Edited README.md to provide very detailed implementation guidelines
- Edited release.sh to properly update the [Unreleased] section
    
### Removed
- 


## [2.0.1] - 2025-1-8

### Added
- Added dev_docs directory with library context and release steps

### Changed
- Edited release.sh to better handle version bumping and tagging
- Updated azure-pipelines.yml to remove dev_docs directory and release.sh upon push to public GitHub.
    
### Removed
    - Removed local-only notes file. Replacement is dev_docs/UPCOMING_UPDATED.md   

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
- README.md and CHANGELOG.md

### Changed
- Cleaned up comments
- Bumped Version to 1.0.1
    
### Fixed
- Updated pipeline.yaml to reference correct repo 



## [1.0.0] - 2025-9-24

### Added
- Initial commit

### Changed
    
### Fixed



[2.0.0]: https://github.com/Eclypses/socketx-client-swift/releases/tag/v2.0.0

[2.0.1]: https://github.com/Eclypses/socketx-client-swift/releases/tag/v2.0.1

[2.0.2]: https://github.com/Eclypses/socketx-client-swift/releases/tag/v2.0.2

[2.1.0]: https://github.com/Eclypses/socketx-client-swift/releases/tag/v2.1.0

[2.1.1]: https://github.com/Eclypses/socketx-client-swift/releases/tag/v2.1.1

[2.1.2]: https://github.com/Eclypses/socketx-client-swift/releases/tag/v2.1.2

[2.1.3]: https://github.com/Eclypses/socketx-client-swift/releases/tag/v2.1.3
