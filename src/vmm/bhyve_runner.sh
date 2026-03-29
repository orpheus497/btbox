#!/bin/sh
##Script function and purpose: Manages the Bhyve VM lifecycle, including networking, module loading, and execution.
#
# btbox - Bhyve Runner
#

set -e

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
HOST_IP=${HOST_IP:-"10.0.0.1"}
GUEST_IP=${GUEST_IP:-"10.0.0.2"}

BTBOX_STATE_FILE="/var/run/btbox.state"
BTBOX_LOCK_FILE="/var/run/btbox.lock"

##Function purpose: Acquire an exclusive lock to prevent concurrent operations.
acquire_lock() {
    # Use mkdir as an atomic lock — portable across POSIX shells
    if ! mkdir "$BTBOX_LOCK_FILE" 2>/dev/null; then
        msg_err "Another btbox operation is in progress (lock: $BTBOX_LOCK_FILE)."
        msg_err "If this is stale, remove it with: rm -rf $BTBOX_LOCK_FILE"
        exit 1
    fi
    # Ensure the lock is released on exit
    trap 'rm -rf "$BTBOX_LOCK_FILE"' EXIT
}

##Function purpose: Clean up resources on exit.
cleanup() {
    if [ -n "$TAP_DEV" ]; then
        msg_info "Cleaning up $TAP_DEV..."
        ifconfig "$TAP_DEV" destroy 2>/dev/null || true
    fi
    rm -f "$BTBOX_STATE_FILE"
    rm -f "${BTBOX_ROOT}/device.map"
    rm -rf "$BTBOX_LOCK_FILE"
}

##Function purpose: Validate that guest build artifacts exist.
check_guest_artifacts() {
    for _artifact in vmlinuz initramfs seed.img; do
        if [ ! -f "${GUEST_DIR}/${_artifact}" ]; then
            msg_err "Guest artifact missing: ${GUEST_DIR}/${_artifact}"
            msg_err "Run 'sh guest/build_alpine.sh' to build the guest image first."
            exit 1
        fi
    done
}

##Function purpose: Wait for the guest VM to become reachable over SSH.
wait_for_guest() {
    _max_wait=${1:-60}
    _attempt=0
    GUEST_SSH_IP="${GUEST_IP:-10.0.0.2}"
    msg_info "Waiting for guest to boot (up to ${_max_wait}s)..."
    while [ "$_attempt" -lt "$_max_wait" ]; do
        if ssh -o BatchMode=yes \
               -o PreferredAuthentications=publickey \
               -o PasswordAuthentication=no \
               -o StrictHostKeyChecking=accept-new \
               -o UserKnownHostsFile=/var/run/btbox_known_hosts \
               -o ConnectTimeout=1 \
               -o ServerAliveInterval=2 \
               -o ServerAliveCountMax=1 \
               "root@${GUEST_SSH_IP}" "echo ok" >/dev/null 2>&1; then
            msg_ok "Guest is ready."
            return 0
        fi
        _attempt=$((_attempt + 2))
        sleep 2
    done
    msg_warn "Guest did not become reachable within ${_max_wait}s."
    msg_warn "It may still be booting. Try 'btbox console' to check."
    return 1
}

##Function purpose: Start the VM.
cmd_start() {
    acquire_lock

    # Set trap for cleanup on error during startup
    trap cleanup EXIT INT TERM

    # Verify guest artifacts exist before attempting boot
    check_guest_artifacts

    ##Step purpose: Load required kernel modules.
    kldload vmm >/dev/null 2>&1 || true
    kldload nmdm >/dev/null 2>&1 || true

    ##Step purpose: Create TAP interface for networking.
    TAP_DEV=$(ifconfig tap create)
    msg_ok "Created $TAP_DEV"

    ##Step purpose: Configure host-side IP on the TAP interface.
    # Point-to-point link between host and guest — no bridge needed for
    # the isolated 10.0.0.0/24 management network.  The host talks
    # directly to the guest over the TAP device.
    HOST_NETMASK="${HOST_NETMASK:-255.255.255.0}"
    ifconfig "$TAP_DEV" inet "$HOST_IP" netmask "$HOST_NETMASK" up

    ##Step purpose: Persist TAP device name and PID for cleanup on stop.
    echo "TAP_DEV=$TAP_DEV" > "$BTBOX_STATE_FILE"

    ##Step purpose: Ensure no stale VM instance exists.
    bhyvectl --destroy --vm="$VM_NAME" >/dev/null 2>&1 || true

    ##Step purpose: Load the kernel and initramfs using grub-bhyve.
    msg_info "Loading Kernel..."

    # Generate device.map for grub (cleaned up on exit)
    DEVICE_MAP="${BTBOX_ROOT}/device.map"
    echo "(host) $GUEST_DIR" > "$DEVICE_MAP"

    # Grub Commands
    grub-bhyve -m "$DEVICE_MAP" -r host -M "$VM_RAM" "$VM_NAME" <<EOF
linux (host)/vmlinuz modules=loop,squashfs,sd-mod,usb-storage console=ttyS0 quiet
initrd (host)/initramfs
boot
EOF

    # Clean up device.map immediately after grub-bhyve finishes
    rm -f "$DEVICE_MAP"

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
        # Verify the PCI device is reserved for passthrough (ppt driver)
        _pci_bsf=$(echo "$PASSTHRU_PCI" | tr '/' ':')
        if command -v pciconf >/dev/null 2>&1; then
            if ! pciconf -l 2>/dev/null | grep -q "ppt.*${_pci_bsf}"; then
                msg_warn "PCI device ${PASSTHRU_PCI} may not be assigned to ppt driver."
                msg_warn "Ensure pptdevs is set in /boot/loader.conf for passthrough."
            fi
        fi
        set -- -s "6,passthru,$PASSTHRU_PCI"
    else
        msg_warn "No PASSTHRU_PCI configured. VM will start without Bluetooth hardware."
        set --
    fi

    # Run bhyve in the background
    bhyve -c "$VM_CPUS" -m "$VM_RAM" -H -A \
        -s 0:0,hostbridge \
        -s 1:0,lpc \
        -s 2:0,virtio-net,"$TAP_DEV" \
        -s 3:0,virtio-blk,"$GUEST_DIR/seed.img" \
        -l com1,"$NMDM_A" \
        "$@" \
        "$VM_NAME" &

    BHYVE_PID=$!

    # Persist state for stop command
    {
        echo "TAP_DEV=$TAP_DEV"
        echo "BHYVE_PID=$BHYVE_PID"
    } > "$BTBOX_STATE_FILE"

    msg_ok "VM Started (PID $BHYVE_PID). Console available via 'btbox console'."

    # Wait for guest to become reachable over SSH
    wait_for_guest 60 || true

    # Release the EXIT trap — stop command handles cleanup from here
    trap - EXIT
    rm -rf "$BTBOX_LOCK_FILE"
}

##Function purpose: Stop and destroy the VM.
cmd_stop() {
    acquire_lock

    if [ ! -e "/dev/vmm/$VM_NAME" ]; then
        msg_err "btbox VM is not running."
        rm -rf "$BTBOX_LOCK_FILE"
        exit 1
    fi

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

    rm -f /var/run/btbox_known_hosts
    rm -rf "$BTBOX_LOCK_FILE"
}

##Action purpose: Dispatch command.
case "$1" in
    start) cmd_start ;;
    stop) cmd_stop ;;
    *) echo "Unknown command"; exit 1 ;;
esac
