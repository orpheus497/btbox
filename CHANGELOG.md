# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0-alpha] - 2026-03-01 (UNRELEASED)

### Added

- **Experimental HID Peripheral Support (guest-side only)**: Bluetooth keyboards, mice, and game controllers can now be paired and used inside the guest via BlueZ HID/HOGP profiles.
- **Input Event Relay (guest-side only)**: Guest-side raw evdev relay service forwards HID events over TCP (base port 7580) for consumption by an external FreeBSD host receiver (not yet included in this repository).
- **Device Info Command**: New `btbox info <MAC>` command shows detailed device information including type and supported profiles.
- **Hardware Check Command**: New `btbox check-hw` command exposes VT-x/VT-d hardware verification directly from the CLI.
- **BlueZ Input Profile**: Enabled `Input` profile and `[Input]` section in BlueZ configuration; guest-side HID event handling is performed by `input-relay.sh`.
- **WirePlumber Audio Node Rules**: Added `bluez_input.*` node matching rule for Bluetooth audio input auto-connect; WirePlumber remains audio-only and does not control HID/input devices (those are handled by `input-relay.sh`).
- **Configuration Options**: Added `BTBOX_INPUT_RELAY` and `BTBOX_INPUT_PORT` config options (reserved for future end-to-end HID relay wiring; not yet propagated from host to guest).
- **Guest Packages**: Added `bluez-plugins`, `eudev`, `libinput`, `socat`, and `evtest` to guest packages for HID support.

### Changed

- **Branding**: Updated project description from "Bluetooth Audio" to "Bluetooth Devices" to reflect broader peripheral support.
- **BlueZ Adapter Class**: Changed from audio-only (`0x200414`) to generic computer class (`0x000100`) to accept all device types.
- **Documentation**: Expanded README with HID peripheral documentation, supported device type table, and usage examples.

### Fixed

- **VM Lifecycle**: Added guest boot readiness wait loop (SSH health check) after bhyve starts, preventing race conditions with immediate `btbox scan/pair/connect` commands.
- **Concurrency**: Added lockfile (`/var/run/btbox.lock`) to prevent simultaneous `btbox start` operations from corrupting state.
- **Networking**: Clarified TAP point-to-point topology with proper `netmask` argument; added default route in guest for host reachability.
- **PCI Passthrough**: Added validation that the passthrough device is assigned to the `ppt` driver before starting bhyve.
- **Guest Artifacts**: Added pre-boot validation that vmlinuz, initramfs, and seed.img exist before attempting to start the VM.
- **SSH Reliability**: Added `ServerAliveInterval`/`ServerAliveCountMax` keepalives and proper error reporting to `guest_exec()`.
- **SSH Key Check**: Added `check_ssh_key()` to warn users at `btbox start` time if no SSH public key has been configured in the overlay.
- **Device Map Cleanup**: device.map is now cleaned up immediately after grub-bhyve and also in the exit trap.
- **Guest Boot Order**: Moved network configuration before `apk update` so package fetching works over the TAP link.
- **Bluetooth Adapter**: Guest now verifies a Bluetooth adapter is present (with retries) before attempting to configure it, providing clear error messages on passthrough failures.
- **PipeWire Startup**: Added per-service startup verification with logging to `/var/log/` for debugging service failures.
- **Builder Integrity**: Added SHA-256 checksum verification for downloaded Alpine ISO images.
- **Builder Portability**: Fixed `makefs` invocation with correct FreeBSD flags (`-o fat_type=16`); added fallback for Linux build hosts using `mkfs.fat`.
- **Config Portability**: Made `stat` calls in `common.sh` portable between FreeBSD (`stat -f`) and GNU/Linux (`stat -c`).
- **Config Security**: Root ownership and permission checks are now skipped for non-root development to allow testing without sudo.
- **VM Stop**: Added state validation (check VM is running) before attempting to destroy, and cleans up known_hosts on stop.

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