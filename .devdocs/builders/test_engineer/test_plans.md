# Test Plan: btbox Core

## Overview
This plan covers the verification of the `btbox` core logic, specifically configuration parsing, security checks, and hardware verification. Since `btbox` relies on kernel modules (`vmm`) and hardware passthrough, end-to-end testing requires a bare-metal FreeBSD environment. CI/CD testing will focus on syntax, linting, and mock logic verification.

## Scope
1.  **Configuration Parsing**: Verify `src/btbox` correctly reads variables and handles missing/malformed configs.
2.  **Security Checks**: Verify root requirement and file permission checks.
3.  **Hardware Verification**: Verify VT-d/IOMMU detection logic (mocked).
4.  **Integration**: Verify the VMM runner constructs the correct `bhyve` command (dry-run).

## Tools
*   `shunit2` (Shell Unit Testing Framework) - To be installed or vendored.
*   `shellcheck` (Static Analysis).
*   GitHub Actions (CI).

## Test Cases

### TC-01: Config Loading
*   **Input**: Valid `btbox.conf`.
*   **Expected**: Variables `$PASSTHRU_PCI`, `$VM_RAM` are set.
*   **Input**: Missing file.
*   **Expected**: Exit code 1, Error message.

### TC-02: Security Permissions
*   **Input**: `btbox.conf` owned by non-root.
*   **Expected**: Exit code 1, Security error.
*   **Input**: `btbox.conf` world-writable.
*   **Expected**: Exit code 1, Security error.

### TC-03: Hardware Check (New Feature)
*   **Input**: `vmm` module not loaded.
*   **Expected**: Attempt to load or Fail.
