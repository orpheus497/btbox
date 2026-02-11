#!/bin/sh
##Script function and purpose: Manages the Bhyve VM lifecycle, including networking, module loading, and execution.
#
# btbox - Bhyve Runner
#

# Load UI Utilities
[ -f "src/ui_utils.sh" ] && . "src/ui_utils.sh"

# Load Config (Same logic as main script, redundant but safe)
CONF_FILE="/usr/local/etc/btbox.conf"
[ -f "conf/btbox.conf.sample" ] && CONF_FILE="conf/btbox.conf.sample"
##Condition purpose: Load config if present.
if [ -f "$CONF_FILE" ]; then . "$CONF_FILE"; fi

VM_NAME="btbox"
GUEST_DIR="guest/output"

# Defaults if not set
VM_RAM=${VM_RAM:-128M}
VM_CPUS=${VM_CPUS:-1}
PASSTHRU_PCI=${PASSTHRU_PCI:-""}

##Function purpose: Start the VM.
cmd_start() {
    ##Step purpose: Load required kernel modules.
    kldload vmm >/dev/null 2>&1 || true
    kldload nmdm >/dev/null 2>&1 || true
    
    ##Step purpose: Create TAP interface for networking.
    # TODO: Implement complex bridge logic. For now, simple TAP.
    TAP_DEV=$(ifconfig tap create)
    msg_ok "Created $TAP_DEV"
    
    ##Step purpose: Ensure no stale VM instance exists.
    bhyvectl --destroy --vm="$VM_NAME" >/dev/null 2>&1 || true
    
    ##Step purpose: Load the kernel and initramfs using grub-bhyve.
    msg_info "Loading Kernel..."
    
    # Generate device.map for grub
    echo "(host) $GUEST_DIR" > device.map
    
    # Grub Commands
    grub-bhyve -m device.map -r host -M "$VM_RAM" "$VM_NAME" <<EOF
linux (host)/vmlinuz modules=loop,squashfs,sd-mod,usb-storage console=ttyS0 quiet
initrd (host)/initramfs
boot
EOF

    ##Step purpose: Execute the bhyve hypervisor.
    msg_info "Starting Hypervisor..."
    
    # Construct PCI Passthrough args
    PASSTHRU_ARG=""
    ##Condition purpose: Add passthrough argument if PCI slot is defined.
    if [ -n "$PASSTHRU_PCI" ]; then
        PASSTHRU_ARG="-s 6,passthru,$PASSTHRU_PCI"
    fi

    # Run in background (daemonize? No, usually we wrap in a supervisor or run &)
    # We use nmdm for console
    bhyve -c "$VM_CPUS" -m "$VM_RAM" -H -A \
        -s 0:0,hostbridge \
        -s 1:0,lpc \
        -s 2:0,virtio-net,"$TAP_DEV" \
        -s 3:0,virtio-blk,"$GUEST_DIR/seed.img" \
        -l com1,/dev/nmdm_btbox_A \
        $PASSTHRU_ARG \
        "$VM_NAME" &
        
    PID=$!
    msg_ok "VM Started (PID $PID). Console available via 'btbox console'."
}

##Function purpose: Stop and destroy the VM.
cmd_stop() {
    msg_info "Destroying VM..."
    bhyvectl --destroy --vm="$VM_NAME"
    msg_ok "VM Stopped."
    # Cleanup TAP?
    # ifconfig tapX destroy... need to track it.
}

##Action purpose: Dispatch command.
case "$1" in
    start) cmd_start ;;
    stop) cmd_stop ;;
    *) echo "Unknown command"; exit 1 ;;
esac