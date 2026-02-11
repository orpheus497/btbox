# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-alpha] - 2026-02-12

### Added
- **Core Logic**: Initial Bhyve wrapper implementation (`src/btbox`, `src/vmm/bhyve_runner.sh`).
- **Guest OS**: Alpine Linux builder script (`guest/build_alpine.sh`) with configuration overlay (apkovl) support.
- **Hardware Check**: Virtualization and IOMMU detection utility (`src/check_hw.sh`).
- **Security**: Strict configuration file ownership and permission checks.
- **UI/UX**: Standardized ANSI-colored output and branded ASCII banner (`src/ui_utils.sh`).
- **Documentation**: Comprehensive `.devdocs` agent-based documentation ecosystem.
- **Testing**: GitHub Actions CI workflow for static analysis and mock testing.
- **Scaffolding**: Makefile and configuration templates.

### Fixed
- **Security**: Fixed unquoted variable expansions in bhyve command to prevent argument injection.
- **Security**: Fixed potential privilege escalation by enforcing root ownership of config files.
