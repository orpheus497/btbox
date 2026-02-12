# Refactoring Plan

## 1. Common Logic (`src/common.sh`)
Centralize configuration loading, UI utility sourcing, and constant definitions.

## 2. Builder Config (`guest/builder.conf`)
Externalize Alpine versions and mirrors.

## 3. Refactoring Targets
*   `src/btbox`: Use `src/common.sh`.
*   `src/vmm/bhyve_runner.sh`: Use `src/common.sh`, add `trap` for TAP cleanup, soft-code NMDM devices.
*   `guest/build_alpine.sh`: Load `guest/builder.conf`.
