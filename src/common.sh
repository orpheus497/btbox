#!/bin/sh
##Script function and purpose: Common library for btbox. Handles config loading, UI inclusion, and shared constants.

# Determine the source directory containing library files.
# Callers must export BTBOX_SRC_DIR before sourcing this file.
# Fallback: use SCRIPT_DIR if it contains ui_utils.sh.
if [ -z "$BTBOX_SRC_DIR" ] || [ ! -f "${BTBOX_SRC_DIR}/ui_utils.sh" ]; then
    if [ -n "$SCRIPT_DIR" ] && [ -f "${SCRIPT_DIR}/ui_utils.sh" ]; then
        BTBOX_SRC_DIR="$SCRIPT_DIR"
    else
        echo "Error: BTBOX_SRC_DIR is not set or does not contain ui_utils.sh." >&2
        echo "Callers must set BTBOX_SRC_DIR to the btbox library directory before sourcing common.sh." >&2
        exit 1
    fi
fi

# Load UI Utilities
. "${BTBOX_SRC_DIR}/ui_utils.sh"

# Constants
VM_NAME="btbox"
NMDM_A="/dev/nmdm_${VM_NAME}_A"
NMDM_B="/dev/nmdm_${VM_NAME}_B"
export NMDM_A NMDM_B

# Project root is one level up from src/
BTBOX_ROOT="$(cd "${BTBOX_SRC_DIR}/.." && pwd)"

##Function purpose: Locate and load the configuration file.
load_config() {
    CONF_FILE="/usr/local/etc/btbox.conf"
    
    # Check for dev mode / local override
    if [ -f "${BTBOX_ROOT}/conf/btbox.conf.sample" ]; then
         CONF_FILE="${BTBOX_ROOT}/conf/btbox.conf.sample"
    fi
    
    # Allow override via environment
    if [ -n "$BTBOX_CONF" ]; then
        CONF_FILE="$BTBOX_CONF"
    fi

    if [ -f "$CONF_FILE" ]; then
        # Security Check: verify file ownership and permissions.
        # Only enforce when running as root (production mode).
        # In dev mode (non-root), the sample config may be user-owned.
        if [ "$(id -u)" -eq 0 ]; then
            # Detect stat flavor: FreeBSD uses -f, GNU/Linux uses -c
            if stat -f "%Su" "$CONF_FILE" >/dev/null 2>&1; then
                # FreeBSD stat
                OWNER=$(stat -f "%Su" "$CONF_FILE")
                OCTAL_PERMS=$(stat -f "%OLp" "$CONF_FILE")
            elif stat -c "%U" "$CONF_FILE" >/dev/null 2>&1; then
                # GNU/Linux stat
                OWNER=$(stat -c "%U" "$CONF_FILE")
                OCTAL_PERMS=$(stat -c "%a" "$CONF_FILE")
            else
                OWNER="unknown"
                OCTAL_PERMS="000"
            fi

            if [ "$OWNER" != "root" ]; then
                 if command -v msg_err >/dev/null; then
                    msg_err "Configuration file $CONF_FILE must be owned by root."
                 else
                    echo "Error: Configuration file $CONF_FILE must be owned by root."
                 fi
                 exit 1
            fi

            # Check permissions (group/world writable) using octal mode
            # Extract the write bit (bit 1) from the group digit (tens place)
            # and the other/world digit (ones place) of the octal permissions.
            # E.g., for mode 0644: group digit=4 (no write), other digit=4 (no write)
            # E.g., for mode 0666: group digit=6 (write), other digit=6 (write)
            GRP_WRITE=$(( (OCTAL_PERMS / 10 % 10) % 4 / 2 ))
            OTH_WRITE=$(( (OCTAL_PERMS % 10) % 4 / 2 ))
            if [ "$GRP_WRITE" -ne 0 ] || [ "$OTH_WRITE" -ne 0 ]; then
                 if command -v msg_err >/dev/null; then
                    msg_err "Configuration file $CONF_FILE is insecure (writable by group/world)."
                 else
                    echo "Error: Configuration file $CONF_FILE is insecure (writable by group/world)."
                 fi
                 exit 1
            fi
        fi

        # shellcheck disable=SC1090
        . "$CONF_FILE"
    else
        if command -v msg_err >/dev/null; then
            msg_err "Configuration file not found at $CONF_FILE"
        else
             echo "Error: Configuration file not found at $CONF_FILE"
        fi
        exit 1
    fi
}
