#!/bin/sh
##Script function and purpose: Monitors Bluetooth HID devices and relays input events to the FreeBSD host over TCP.
#
# btbox Input Event Relay
# Runs inside the guest VM.
# Watches for new Bluetooth HID devices (keyboards, mice, game controllers)
# and forwards their evdev events to the host via a TCP socket (port 7580).
#
# The host-side receiver (btbox) reconstructs these as virtual input devices
# using cuse(3) or uhid(4).

set -e

RELAY_PORT="${BTBOX_INPUT_PORT:-7580}"
RELAY_PIDDIR="/run/btbox"
INPUT_DIR="/dev/input"

mkdir -p "$RELAY_PIDDIR"

##Function purpose: Check if an input device is a Bluetooth device.
is_bluetooth_device() {
    _dev_path="$1"
    _dev_name=$(basename "$_dev_path")
    _sysfs="/sys/class/input/${_dev_name}/device"
    # Check if the device's parent bus is Bluetooth (bus type 0x05)
    if [ -f "${_sysfs}/id/bustype" ]; then
        _bustype=$(cat "${_sysfs}/id/bustype" 2>/dev/null)
        # 0x0005 = Bluetooth bus type in Linux input subsystem
        if [ "$_bustype" = "0005" ]; then
            return 0
        fi
    fi
    # Also check via udevadm for Bluetooth HID
    if command -v udevadm >/dev/null 2>&1; then
        if udevadm info --query=property --name="$_dev_path" 2>/dev/null | grep -qi "ID_BUS=bluetooth"; then
            return 0
        fi
    fi
    return 1
}

##Function purpose: Relay events from a single input device to the host.
relay_device() {
    _dev="$1"
    _dev_name=$(basename "$_dev")
    _pid_file="${RELAY_PIDDIR}/relay_${_dev_name}.pid"

    # Don't start a duplicate relay
    if [ -f "$_pid_file" ] && kill -0 "$(cat "$_pid_file")" 2>/dev/null; then
        return 0
    fi

    echo ">> btbox-input: Relaying ${_dev_name} to host on port ${RELAY_PORT}"
    # Use evtest --grab to read events; pipe binary evdev data over TCP
    # The host-side receiver parses the evdev struct (type, code, value)
    if command -v evtest >/dev/null 2>&1; then
        evtest --grab "$_dev" 2>/dev/null | nc -lk -p "$RELAY_PORT" &
        echo $! > "$_pid_file"
    fi
}

##Function purpose: Scan for and relay new Bluetooth HID devices.
scan_and_relay() {
    if [ ! -d "$INPUT_DIR" ]; then
        return
    fi
    for dev in "${INPUT_DIR}"/event*; do
        [ -e "$dev" ] || continue
        if is_bluetooth_device "$dev"; then
            relay_device "$dev"
        fi
    done
}

##Action purpose: Main loop - periodically scan for new BT HID devices.
echo ">> btbox-input: Input relay started (port ${RELAY_PORT})"
while true; do
    scan_and_relay
    sleep 5
done
