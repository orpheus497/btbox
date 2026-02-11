# Formatting Standards

## Shell Script Standards
*   **Indent:** 4 spaces (soft tabs).
*   **Comments:** Strict "Purpose" prefixes required for all major blocks.
    *   `##Script function and purpose:`
    *   `##Function purpose:`
    *   `##Step purpose:`
    *   `##Condition purpose:`
    *   `##Action purpose:`
    *   `##Error purpose:`
*   **Naming:** Snake_case for variables and functions.
*   **Shebang:** `#!/bin/sh` (POSIX compliant preferred where possible).

## Enforced files
*   `src/btbox`
*   `src/vmm/bhyve_runner.sh`
*   `guest/build_alpine.sh`
*   `guest/overlay/etc/local.d/btbox.start`
