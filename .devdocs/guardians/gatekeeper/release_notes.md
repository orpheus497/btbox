# Release Notes: v0.1.0-alpha

**Date:** 2026-02-12T10:45:00Z
**Release Manager:** Agent B10 (The Gatekeeper)

## Summary
This is the initial Alpha release of **btbox**, a FreeBSD utility for Bluetooth Audio virtualization. It establishes the core architecture using Bhyve and Alpine Linux.

## Artifacts
*   **Source Code**: `src/` (Core logic)
*   **Builder**: `guest/build_alpine.sh` (Guest OS generation)
*   **Config**: `conf/btbox.conf.sample`
*   **License**: BSD 2-Clause

## Validation
*   **Security**: Audited and Hardened (Agent B6).
*   **Logic**: Verified Mock Tests (Agent A4).
*   **Style**: Compliant with Project Standards (Agent B7).
*   **Documentation**: Synchronized (Agent A5).

## Known Issues
*   Requires manual "passthrough" configuration of USB controllers.
*   No suspend/resume support yet.
*   Integration tests require bare-metal hardware.
