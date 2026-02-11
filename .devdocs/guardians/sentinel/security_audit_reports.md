# Security Audit Report

**Date:** 2026-02-12T10:00:00Z
**Auditor:** Agent B6 (The Sentinel)
**Target:** `btbox` core scripts

## Executive Summary
The `btbox` utility requires `root` privileges to operate the Bhyve hypervisor. This inherently carries high risk. The current implementation performs basic root checks but lacks input sanitization for configuration variables, potentially allowing argument injection if the configuration file is compromised. Additionally, the Guest OS exposes the PipeWire audio service on all network interfaces (0.0.0.0), which relies entirely on the Host's network isolation for security.

## Findings

### 1. Unquoted Variable Expansion (High)
**File:** `src/vmm/bhyve_runner.sh`
**Location:** The `bhyve` execution command.
**Issue:** The `$PASSTHRU_ARG` and `$TAP_DEV` variables are expanded without quotes. While standard shell variable expansion does not typically execute embedded commands (like `; rm -rf /`), it *does* perform word splitting. A malicious PCI ID containing spaces could alter the arguments passed to the `bhyve` binary, potentially changing device mapping or flags.
**Recommendation:** Quote all variable expansions where possible, or validate the PCI format strictly (Regex: `^[0-9]+/[0-9]+/[0-9]+$`).

### 2. Config File Permissions (Medium)
**File:** `src/btbox`
**Issue:** The script sources (`.`) the configuration file. This executes the file as a shell script. If the configuration file is writable by a non-root user, that user can escalate privileges to root when `btbox` is run by an administrator.
**Recommendation:** Add a check to ensure `btbox.conf` is owned by `root` and not writable by others before sourcing it.

### 3. Open Audio Port (Medium)
**File:** `guest/overlay/etc/pipewire/pipewire-pulse.conf`
**Issue:** `server.address = [ "unix:native", "tcp:4713" ]` binds to all interfaces.
**Context:** The VM is bridged. If the bridge is connected to a physical LAN without filtering, port 4713 is exposed to the LAN.
**Recommendation:** Documentation must explicitly state that the Guest IP should be isolated or firewalled.

### 4. Temporary File Cleanup (Low)
**File:** `guest/build_alpine.sh`
**Issue:** The script creates `guest/build/seed` but does not guarantee cleanup if the script fails (no `trap`).
**Recommendation:** Implement a `trap` to remove temporary directories on exit/interrupt.

## Action Plan
1.  **Harden `src/vmm/bhyve_runner.sh`:** Quote variables.
2.  **Harden `src/btbox`:** Add file permission check for config.
3.  **Update Config Docs:** Warn about `PASSTHRU_PCI` format.
