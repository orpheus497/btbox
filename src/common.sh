#!/bin/sh
##Script function and purpose: Common library for btbox. Handles config loading, UI inclusion, and shared constants.

# Determine the source directory containing library files.
# If BTBOX_SRC_DIR is already set by the caller (e.g. bhyve_runner.sh),
# use that. Otherwise, derive it from $0 or SCRIPT_DIR.
if [ -z "$BTBOX_SRC_DIR" ] || [ ! -f "${BTBOX_SRC_DIR}/ui_utils.sh" ]; then
    if [ -n "$SCRIPT_DIR" ] && [ -f "${SCRIPT_DIR}/ui_utils.sh" ]; then
        BTBOX_SRC_DIR="$SCRIPT_DIR"
    else
        BTBOX_SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
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
        # Security Check: verify file is owned by root (FreeBSD stat)
        OWNER=$(stat -f "%Su" "$CONF_FILE")
        if [ "$OWNER" != "root" ]; then
             if command -v msg_err >/dev/null; then
                msg_err "Configuration file $CONF_FILE must be owned by root."
             else
                echo "Error: Configuration file $CONF_FILE must be owned by root."
             fi
             exit 1
        fi
        
        # Check permissions (group/world writable)
        PERMS=$(stat -f "%Sp" "$CONF_FILE")
        if echo "$PERMS" | grep -q "^....w" || echo "$PERMS" | grep -q "^.......w"; then
             if command -v msg_err >/dev/null; then
                msg_err "Configuration file $CONF_FILE is insecure (writable by group/world)."
             else
                echo "Error: Configuration file $CONF_FILE is insecure (writable by group/world)."
             fi
             exit 1
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
