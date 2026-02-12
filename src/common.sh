#!/bin/sh
##Script function and purpose: Common library for btbox. Handles config loading, UI inclusion, and shared constants.

# Load UI Utilities
[ -f "src/ui_utils.sh" ] && . "src/ui_utils.sh"
[ -f "../src/ui_utils.sh" ] && . "../src/ui_utils.sh"

# Constants
VM_NAME="btbox"
NMDM_A="/dev/nmdm_${VM_NAME}_A"
NMDM_B="/dev/nmdm_${VM_NAME}_B"

##Function purpose: Locate and load the configuration file.
load_config() {
    CONF_FILE="/usr/local/etc/btbox.conf"
    
    # Check for dev mode / local override
    if [ -f "conf/btbox.conf.sample" ]; then
         CONF_FILE="conf/btbox.conf.sample"
    elif [ -f "../conf/btbox.conf.sample" ]; then
         CONF_FILE="../conf/btbox.conf.sample"
    fi
    
    # Allow override via environment
    if [ -n "$BTBOX_CONF" ]; then
        CONF_FILE="$BTBOX_CONF"
    fi

    if [ -f "$CONF_FILE" ]; then
        # Security Check
        OWNER=$(ls -l "$CONF_FILE" | awk '{print $3}')
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
