# Code Smell Report

**Date:** 2026-02-12T10:50:00Z
**Auditor:** Agent B9 (The Critic)

## Identified Code Smells

### 1. Duplicated Code (Config Path Logic)
*   **Location:** `src/btbox` and `src/vmm/bhyve_runner.sh`.
*   **Description:** Both scripts implement logic to find the config file (checking `/usr/local/etc`, `conf/`, and `.dev_mode`).
*   **Risk:** Inconsistency if the config location changes.
*   **Remedy:** Move config resolution logic to a shared helper script (e.g., `src/common.sh`).

### 2. Hardcoded Values
*   **Location:** `guest/build_alpine.sh`.
*   **Description:** Alpine version and mirror URL are hardcoded constants.
*   **Risk:** Difficult to upgrade without modifying the script.
*   **Remedy:** Move these to a `build.conf` or the main `btbox.conf`.

### 3. "Magic" Strings
*   **Location:** `src/vmm/bhyve_runner.sh`.
*   **Description:** Device names like `nmdm_btbox_A` and `nmdm_btbox_B` are hardcoded throughout the logic.
*   **Remedy:** Define these as variables at the top of the script.

### 4. Lack of Signal Handling (Cleanup)
*   **Location:** `src/vmm/bhyve_runner.sh`.
*   **Description:** TAP devices are created but never explicitly destroyed if the script or VM fails unexpectedly.
*   **Remedy:** Implement `trap` to cleanup interfaces on script exit.
