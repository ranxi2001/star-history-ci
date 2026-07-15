# Changelog

## [Unreleased]

- Document direct PAT and per-repository Actions Secret setup for consuming projects.

## [2.0.0] - 2026-07-15

### Breaking

- Require an admin or collaborator PAT for GitHub's restricted stargazer listing API.

### Added

- Vendor the renderer source and locked dependencies into this repository.
- Add offline renderer, access-control, filename, and publishing tests.

### Changed

- Replace third-party render and output-branch Actions with local scripts.
- Preserve GitHub's real 403 message and reject restricted empty stargazer responses.

### Removed

- Remove the standalone workflow that depended on third-party Actions.

## [1.0.0] - 2026-07-09

- Initial reusable GitHub Action wrapper for publishing stable star-history SVGs.
- Add English and Simplified Chinese README files.

[Unreleased]: https://github.com/ranxi2001/star-history-ci/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/ranxi2001/star-history-ci/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/ranxi2001/star-history-ci/releases/tag/v1.0.0
