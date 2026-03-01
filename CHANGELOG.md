# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0-alpha] - 2026-03-01 (UNRELEASED)

### Added
- **Experimental HID Peripheral Support (guest-side only)**: Bluetooth keyboards, mice, and game controllers can now be paired and used inside the guest via BlueZ HID/HOGP profiles.
- **Input Event Relay (guest-side only)**: Guest-side raw evdev relay service forwards HID events over TCP (base port 7580) for consumption by an external FreeBSD host receiver (not yet included in this repository).
- **Device Info Command**: New `btbox info <MAC>` command shows detailed device information including type and supported profiles.
- **BlueZ Input Profile**: Enabled `Input` profile and `[Input]` section in BlueZ configuration for HID device handling.
- **WirePlumber HID Rules**: Added device matching rules for Bluetooth input/HID devices.
- **Configuration Options**: Added `BTBOX_INPUT_RELAY` and `BTBOX_INPUT_PORT` config options (reserved for future end-to-end HID relay wiring).
- **Guest Packages**: Added `bluez-plugins`, `eudev`, `libinput`, `socat`, and `evtest` to guest packages for HID support.

### Changed
- **Branding**: Updated project description from "Bluetooth Audio" to "Bluetooth Devices" to reflect broader peripheral support.
- **BlueZ Adapter Class**: Changed from audio-only (`0x200414`) to generic computer class (`0x000100`) to accept all device types.
- **Documentation**: Expanded README with HID peripheral documentation, supported device type table, and usage examples.

## [0.1.0-alpha] - 2026-02-12 (UNRELEASED)

### Added
- **Project Identity**: Formally identified **orpheus497** as the project creator and primary maintainer.
- **Detailed Documentation**: Expanded `README.md` with technical purpose, inspiration credits (`wifibox`), and dependency acknowledgments.
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