#!/bin/sh
##Script function and purpose: Manages the Bhyve VM lifecycle, including networking, module loading, and execution.
#
# btbox - Bhyve Runner
#

# Resolve the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BTBOX_SRC_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load Common Library
. "${BTBOX_SRC_DIR}/common.sh"

##Action purpose: Load configuration.
load_config

# Derive paths from data directory (configurable for installed vs source layout)
BTBOX_DATA_DIR=${BTBOX_DATA_DIR:-"${BTBOX_ROOT}"}
GUEST_DIR="${BTBOX_DATA_DIR}/guest/output"

# Defaults if not set
VM_RAM=${VM_RAM:-128M}
VM_CPUS=${VM_CPUS:-1}
PASSTHRU_PCI=${PASSTHRU_PCI:-""}

BTBOX_STATE_FILE="/var/run/btbox.state"

##Function purpose: Clean up resources on exit.
cleanup() {
    if [ -n "$TAP_DEV" ]; then
        msg_info "Cleaning up $TAP_DEV..."
        ifconfig "$TAP_DEV" destroy 2>/dev/null || true
        rm -f "$BTBOX_STATE_FILE"
    fi
}

##Function purpose: Start the VM.
cmd_start() {
    # Set trap for cleanup
    trap cleanup EXIT INT TERM

    ##Step purpose: Load required kernel modules.
    kldload vmm >/dev/null 2>&1 || true
    kldload nmdm >/dev/null 2>&1 || true
    
    ##Step purpose: Create TAP interface for networking.
    # TODO: Implement complex bridge logic. For now, simple TAP.
    TAP_DEV=$(ifconfig tap create)
    msg_ok "Created $TAP_DEV"
    
    ##Step purpose: Configure host-side IP on the TAP interface.
    HOST_NETMASK="${HOST_NETMASK:-255.255.255.0}"
    ifconfig "$TAP_DEV" inet "$HOST_IP" "$HOST_NETMASK"
    
    ##Step purpose: Persist TAP device name for cleanup on stop.
    echo "TAP_DEV=$TAP_DEV" > "$BTBOX_STATE_FILE"
    
    ##Step purpose: Ensure no stale VM instance exists.
    bhyvectl --destroy --vm="$VM_NAME" >/dev/null 2>&1 || true
    
    ##Step purpose: Load the kernel and initramfs using grub-bhyve.
    msg_info "Loading Kernel..."
    
    # Generate device.map for grub
    DEVICE_MAP="${BTBOX_ROOT}/device.map"
    echo "(host) $GUEST_DIR" > "$DEVICE_MAP"
    
    # Grub Commands
    grub-bhyve -m "$DEVICE_MAP" -r host -M "$VM_RAM" "$VM_NAME" <<EOF
linux (host)/vmlinuz modules=loop,squashfs,sd-mod,usb-storage console=ttyS0 quiet
initrd (host)/initramfs
boot
EOF

    ##Step purpose: Execute the bhyve hypervisor.
    msg_info "Starting Hypervisor..."
    
    # Construct PCI Passthrough args
    ##Condition purpose: Add passthrough argument if PCI slot is defined.
    # Validate PASSTHRU_PCI format (bus/slot/function) to prevent injection
    if [ -n "$PASSTHRU_PCI" ]; then
        if ! echo "$PASSTHRU_PCI" | grep -qE '^[0-9]+/[0-9]+/[0-9]+$'; then
            msg_err "Invalid PASSTHRU_PCI format: $PASSTHRU_PCI (expected bus/slot/function, e.g. 0/20/0)"
            exit 1
        fi
        set -- -s "6,passthru,$PASSTHRU_PCI"
    else
        set --
    fi

    # Run in background (daemonize? No, usually we wrap in a supervisor or run &)
    # We use nmdm for console
    bhyve -c "$VM_CPUS" -m "$VM_RAM" -H -A \
        -s 0:0,hostbridge \
        -s 1:0,lpc \
        -s 2:0,virtio-net,"$TAP_DEV" \
        -s 3:0,virtio-blk,"$GUEST_DIR/seed.img" \
        -l com1,"$NMDM_A" \
        "$@" \
        "$VM_NAME" &
        
    PID=$!
    msg_ok "VM Started (PID $PID). Console available via 'btbox console'."
    
    # Wait for the VM process so trap works (if running in foreground)
    # Since we run in background for 'start' command, we detach.
    # We explicitly untrap if we successfully detach.
    trap - EXIT
}

##Function purpose: Stop and destroy the VM.
cmd_stop() {
    msg_info "Destroying VM..."
    bhyvectl --destroy --vm="$VM_NAME"
    msg_ok "VM Stopped."
    # Clean up the TAP interface tracked from the start command.
    if [ -f "$BTBOX_STATE_FILE" ]; then
        # shellcheck disable=SC1090
        . "$BTBOX_STATE_FILE"
        if [ -n "$TAP_DEV" ]; then
            msg_info "Cleaning up $TAP_DEV..."
            ifconfig "$TAP_DEV" destroy 2>/dev/null || true
        fi
        rm -f "$BTBOX_STATE_FILE"
    fi
}

##Action purpose: Dispatch command.
case "$1" in
    start) cmd_start ;;
    stop) cmd_stop ;;
    *) echo "Unknown command"; exit 1 ;;
esac