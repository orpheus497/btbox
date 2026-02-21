#!/bin/sh
##Script function and purpose: Helper script to check for hardware virtualization support (VT-x/SVM and VT-d/IOMMU).

# Resolve the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load UI
. "${SCRIPT_DIR}/ui_utils.sh"

check_hw() {
    msg_info "Checking Hardware Support..."
    
    # Check CPU Support (VMX/SVM)
    if dmesg | grep -qE "VMX|SVM"; then
        msg_ok "CPU Virtualization supported."
    else
        msg_warn "CPU Virtualization (VMX/SVM) not detected in dmesg. (Might be cleared, check BIOS)."
    fi

    # Check IOMMU (VT-d/AMD-Vi)
    if acpidump -t | grep -q "DMAR"; then
         msg_ok "IOMMU (DMAR/VT-d) ACPI Table found."
    elif acpidump -t | grep -q "IVRS"; then
         msg_ok "IOMMU (IVRS/AMD-Vi) ACPI Table found."
    else
         msg_err "IOMMU support not found. Passthrough will NOT work."
         return 1
    fi
    
    return 0
}

# Run if called directly
if [ "$(basename "$0")" = "check_hw.sh" ]; then
    check_hw
fi
