#!/bin/sh
##Script function and purpose: Monitors Bluetooth HID devices and relays raw input events to the FreeBSD host over TCP.
#
# btbox Input Event Relay (experimental / guest-side only)
# Runs inside the guest VM.
# Watches for new Bluetooth HID devices (keyboards, mice, game controllers)
# and forwards raw evdev events to the host via a TCP socket.
#
# NOTE: A host-side receiver is required to consume the raw struct input_event
# stream and reconstruct virtual input devices (e.g. via cuse(3) or uhid(4)).
# The host-side receiver is not yet included in this repository.

set -e

RELAY_PIDDIR="/run/btbox"
INPUT_DIR="/dev/input"

##Function purpose: Validate that a value is a numeric port in range 1-65535.
validate_port() {
    _val="$1"
    _default="$2"
    case "$_val" in
        ''|*[!0-9]*)
            echo "$_default"
            return
            ;;
    esac
    if [ "$_val" -ge 1 ] && [ "$_val" -le 65535 ]; then
        echo "$_val"
    else
        echo "$_default"
    fi
}

##Function purpose: Validate that a value looks like a plausible IPv4 address or hostname.
validate_bind() {
    _val="$1"
    _default="$2"
    # Accept IPv4 dotted-quad or simple hostnames (alphanumeric + dots/hyphens)
    case "$_val" in
        *[!0-9.a-zA-Z-]*)
            echo "$_default"
            return
            ;;
    esac
    if [ -n "$_val" ]; then
        echo "$_val"
    else
        echo "$_default"
    fi
}

RELAY_PORT=$(validate_port "${BTBOX_INPUT_PORT:-7580}" "7580")
RELAY_BIND=$(validate_bind "${BTBOX_RELAY_BIND:-10.0.0.2}" "10.0.0.2")
RELAY_PIDFILE="${RELAY_PIDDIR}/input-relay.pid"

mkdir -p "$RELAY_PIDDIR"

# Check for an existing relay process before starting
if [ -f "$RELAY_PIDFILE" ]; then
    _existing=$(cat "$RELAY_PIDFILE" 2>/dev/null)
    case "$_existing" in
        ''|*[!0-9]*)
            rm -f "$RELAY_PIDFILE"
            ;;
        *)
            if kill -0 "$_existing" 2>/dev/null; then
                _cmd=$(ps -p "$_existing" -o comm= 2>/dev/null || true)
                case "$_cmd" in
                    *sh*|*input-relay*)
                        echo ">> btbox-input: Relay already running (PID $_existing), exiting."
                        exit 0
                        ;;
                esac
            fi
            rm -f "$RELAY_PIDFILE"
            ;;
    esac
fi

# Record our own PID for graceful shutdown
echo $$ > "$RELAY_PIDFILE"

##Function purpose: Clean up child socat processes and stale pidfiles on exit.
cleanup_relay() {
    echo ">> btbox-input: Shutting down input relay..."
    for _pf in "${RELAY_PIDDIR}"/relay_event*.pid; do
        [ -f "$_pf" ] || continue
        _pid=$(cat "$_pf" 2>/dev/null)
        case "$_pid" in
            ''|*[!0-9]*) rm -f "$_pf"; continue ;;
        esac
        if kill -0 "$_pid" 2>/dev/null; then
            kill "$_pid" 2>/dev/null || true
        fi
        rm -f "$_pf"
    done
    rm -f "$RELAY_PIDFILE"
    echo ">> btbox-input: Input relay stopped."
}
trap cleanup_relay INT TERM EXIT

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

##Function purpose: Relay raw evdev events from a single input device to the host.
relay_device() {
    _dev="$1"
    _dev_name=$(basename "$_dev")
    _pid_file="${RELAY_PIDDIR}/relay_${_dev_name}.pid"

    # Don't start a duplicate relay — validate PID is numeric and belongs to
    # a socat process started by this relay before treating it as active.
    if [ -f "$_pid_file" ]; then
        _existing_pid=$(cat "$_pid_file" 2>/dev/null)
        case "$_existing_pid" in
            ''|*[!0-9]*)
                # Non-numeric PID — stale file
                rm -f "$_pid_file"
                ;;
            *)
                if kill -0 "$_existing_pid" 2>/dev/null; then
                    # Verify the process belongs to this relay (socat)
                    _cmd=$(ps -p "$_existing_pid" -o comm= 2>/dev/null || true)
                    case "$_cmd" in
                        *socat*) return 0 ;;
                    esac
                fi
                # PID not running or not ours — remove stale file
                rm -f "$_pid_file"
                ;;
        esac
    fi

    # Assign a unique port per device to avoid listener conflicts.
    # Extract event number (e.g. event3 -> 3) and offset from base port.
    _event_num=$(echo "$_dev_name" | sed 's/[^0-9]//g')
    _dev_port=$((RELAY_PORT + _event_num))
    _dev_port=$(validate_port "$_dev_port" "")
    if [ -z "$_dev_port" ]; then
        echo ">> btbox-input: Skipping ${_dev_name}: computed port out of range"
        return 0
    fi

    echo ">> btbox-input: Relaying ${_dev_name} to host on ${RELAY_BIND}:${_dev_port}"
    # Read raw evdev events (struct input_event) from the device node and
    # forward them over TCP. Uses socat to only open the device when a host
    # client connects, avoiding blocked reads when no receiver is attached.
    # Bind to the guest-only bridge IP to prevent exposure on other interfaces.
    # Validate the device path is within /dev/input/ to prevent arbitrary reads.
    case "$_dev" in
        /dev/input/event*)
            if command -v socat >/dev/null 2>&1; then
                socat -u OPEN:"$_dev",rdonly TCP-LISTEN:"$_dev_port",bind="$RELAY_BIND",reuseaddr,fork &
                echo $! > "$_pid_file"
            fi
            ;;
        *)
            echo ">> btbox-input: Skipping invalid device path: $_dev"
            ;;
    esac
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
echo ">> btbox-input: Input relay started (bind ${RELAY_BIND}, base port ${RELAY_PORT})"
while true; do
    scan_and_relay
    sleep 5
done
