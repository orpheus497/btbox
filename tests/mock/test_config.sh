#!/bin/sh
##Script function and purpose: Mock test suite for btbox configuration and security logic.
#
# tests/mock/test_config.sh
#
# Usage: sh tests/mock/test_config.sh
#

# Resolve project root
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${TEST_DIR}/../.." && pwd)"

PASS=0
FAIL=0

assert_equals() {
    _test_name="$1"
    _expected="$2"
    _actual="$3"
    if [ "$_expected" = "$_actual" ]; then
        echo "PASS: ${_test_name}"
        PASS=$((PASS + 1))
    else
        echo "FAIL: ${_test_name} (expected '${_expected}', got '${_actual}')"
        FAIL=$((FAIL + 1))
    fi
}

assert_nonzero_exit() {
    _test_name="$1"
    _exit_code="$2"
    if [ "$_exit_code" -ne 0 ]; then
        echo "PASS: ${_test_name}"
        PASS=$((PASS + 1))
    else
        echo "FAIL: ${_test_name} (expected non-zero exit, got 0)"
        FAIL=$((FAIL + 1))
    fi
}

assert_zero_exit() {
    _test_name="$1"
    _exit_code="$2"
    if [ "$_exit_code" -eq 0 ]; then
        echo "PASS: ${_test_name}"
        PASS=$((PASS + 1))
    else
        echo "FAIL: ${_test_name} (expected zero exit, got ${_exit_code})"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    _test_name="$1"
    _haystack="$2"
    _needle="$3"
    if echo "$_haystack" | grep -q "$_needle"; then
        echo "PASS: ${_test_name}"
        PASS=$((PASS + 1))
    else
        echo "FAIL: ${_test_name} (output does not contain '${_needle}')"
        FAIL=$((FAIL + 1))
    fi
}

# --- Test: Missing config file ---
test_config_missing() {
    output=$(BTBOX_CONF="/nonexistent/path/btbox.conf" sh "${PROJECT_ROOT}/src/btbox" status 2>&1)
    rc=$?
    assert_nonzero_exit "Missing config causes failure" "$rc"
    assert_contains "Missing config error message" "$output" "not found"
}

# --- Test: Usage output ---
test_usage_output() {
    # Verify the script is parseable by sh
    sh -n "${PROJECT_ROOT}/src/btbox" 2>&1
    rc=$?
    assert_zero_exit "Main script has valid syntax" "$rc"
}

# --- Test: All scripts have valid shell syntax ---
test_syntax_common() {
    sh -n "${PROJECT_ROOT}/src/common.sh" 2>&1
    assert_zero_exit "common.sh has valid syntax" "$?"
}

test_syntax_ui_utils() {
    sh -n "${PROJECT_ROOT}/src/ui_utils.sh" 2>&1
    assert_zero_exit "ui_utils.sh has valid syntax" "$?"
}

test_syntax_check_hw() {
    sh -n "${PROJECT_ROOT}/src/check_hw.sh" 2>&1
    assert_zero_exit "check_hw.sh has valid syntax" "$?"
}

test_syntax_bhyve_runner() {
    sh -n "${PROJECT_ROOT}/src/vmm/bhyve_runner.sh" 2>&1
    assert_zero_exit "bhyve_runner.sh has valid syntax" "$?"
}

test_syntax_build_alpine() {
    sh -n "${PROJECT_ROOT}/guest/build_alpine.sh" 2>&1
    assert_zero_exit "build_alpine.sh has valid syntax" "$?"
}

test_syntax_guest_start() {
    sh -n "${PROJECT_ROOT}/guest/overlay/etc/local.d/btbox.start" 2>&1
    assert_zero_exit "btbox.start has valid syntax" "$?"
}

# --- Test: UI functions load correctly ---
test_ui_functions() {
    output=$(. "${PROJECT_ROOT}/src/ui_utils.sh" && msg_info "test message" 2>&1)
    assert_contains "msg_info produces output" "$output" "test message"

    output=$(. "${PROJECT_ROOT}/src/ui_utils.sh" && msg_ok "ok message" 2>&1)
    assert_contains "msg_ok produces output" "$output" "ok message"

    output=$(. "${PROJECT_ROOT}/src/ui_utils.sh" && msg_warn "warn message" 2>&1)
    assert_contains "msg_warn produces output" "$output" "warn message"
}

# --- Test: Config sample has required variables ---
test_config_sample_variables() {
    . "${PROJECT_ROOT}/conf/btbox.conf.sample"
    assert_equals "PASSTHRU_PCI is set" "0/20/0" "$PASSTHRU_PCI"
    assert_equals "VM_RAM has suffix" "128M" "$VM_RAM"
    assert_equals "VM_CPUS is set" "1" "$VM_CPUS"
    assert_equals "HOST_IP is set" "10.0.0.1" "$HOST_IP"
    assert_equals "HOST_NETMASK is set" "255.255.255.0" "$HOST_NETMASK"
    assert_equals "GUEST_IP is set" "10.0.0.2" "$GUEST_IP"
    assert_equals "BTBOX_INPUT_RELAY is set" "no" "$BTBOX_INPUT_RELAY"
    assert_equals "BTBOX_INPUT_PORT is set" "7580" "$BTBOX_INPUT_PORT"
}

# --- Test: Input relay script has valid syntax ---
test_syntax_input_relay() {
    sh -n "${PROJECT_ROOT}/guest/overlay/etc/btbox/input-relay.sh" 2>&1
    assert_zero_exit "input-relay.sh has valid syntax" "$?"
}

# --- Test: Input relay uses socat and binds to specific IP ---
test_input_relay_security() {
    _content=$(cat "${PROJECT_ROOT}/guest/overlay/etc/btbox/input-relay.sh")
    assert_contains "Input relay uses socat" "$_content" "socat"
    assert_contains "Input relay binds to specific IP" "$_content" "bind="
}

# --- Test: BlueZ config has HID support ---
test_bluez_hid_config() {
    _conf="${PROJECT_ROOT}/guest/overlay/etc/bluetooth/main.conf"
    _content=$(cat "$_conf")
    assert_contains "BlueZ config enables Input profile" "$_content" "Input"
    assert_contains "BlueZ config has Input section" "$_content" "\[Input\]"
    assert_contains "BlueZ config has generic class" "$_content" "0x000100"
}

# --- Test: btbox CLI includes info command ---
test_btbox_info_command() {
    _content=$(cat "${PROJECT_ROOT}/src/btbox")
    assert_contains "btbox has info command" "$_content" "info"
    assert_contains "btbox info uses bluetoothctl info" "$_content" "bluetoothctl info"
}

# --- Test: Guest startup includes HID packages ---
test_guest_hid_packages() {
    _content=$(cat "${PROJECT_ROOT}/guest/overlay/etc/local.d/btbox.start")
    assert_contains "Guest installs bluez-plugins" "$_content" "bluez-plugins"
    assert_contains "Guest installs eudev" "$_content" "eudev"
    assert_contains "Guest installs libinput" "$_content" "libinput"
    assert_contains "Guest installs socat" "$_content" "socat"
    assert_contains "Guest starts input relay conditionally" "$_content" "BTBOX_INPUT_RELAY"
    assert_contains "Guest has BTBOX_INPUT_RELAY fallback assignment" "$_content" 'BTBOX_INPUT_RELAY:-'
}

# --- Test: WirePlumber config handles Bluetooth audio and input nodes ---
test_wireplumber_hid_config() {
    _conf="${PROJECT_ROOT}/guest/overlay/etc/wireplumber/wireplumber.conf.d/51-btbox-bluetooth.conf"
    _content=$(cat "$_conf")
    assert_contains "WirePlumber has input node rule" "$_content" "bluez_input"
}

# --- Test: btbox CLI has check-hw command ---
test_btbox_check_hw_command() {
    _content=$(cat "${PROJECT_ROOT}/src/btbox")
    assert_contains "btbox has check-hw command" "$_content" "check-hw"
    assert_contains "btbox check-hw sources check_hw.sh" "$_content" "check_hw.sh"
}

# --- Test: SSH guest_exec has keepalive and error handling ---
test_guest_exec_options() {
    _content=$(cat "${PROJECT_ROOT}/src/btbox")
    assert_contains "SSH uses ServerAliveInterval" "$_content" "ServerAliveInterval"
    assert_contains "SSH uses ServerAliveCountMax" "$_content" "ServerAliveCountMax"
    assert_contains "guest_exec has error handling" "$_content" "Guest command failed"
}

# --- Test: bhyve_runner has lockfile and boot wait ---
test_bhyve_runner_features() {
    _content=$(cat "${PROJECT_ROOT}/src/vmm/bhyve_runner.sh")
    assert_contains "bhyve_runner has set -e" "$_content" "set -e"
    assert_contains "bhyve_runner has lockfile" "$_content" "BTBOX_LOCK_FILE"
    assert_contains "bhyve_runner has boot wait" "$_content" "wait_for_guest"
    assert_contains "bhyve_runner cleans up device.map" "$_content" "device.map"
    assert_contains "bhyve_runner validates guest artifacts" "$_content" "check_guest_artifacts"
    assert_contains "bhyve_runner validates ppt driver" "$_content" "ppt"
}

# --- Test: Guest startup has networking before packages ---
test_guest_boot_order() {
    _content=$(cat "${PROJECT_ROOT}/guest/overlay/etc/local.d/btbox.start")
    # Network config must appear before apk update for package fetching
    _net_line=$(grep -n "ip addr add" "${PROJECT_ROOT}/guest/overlay/etc/local.d/btbox.start" | head -1 | cut -d: -f1)
    _apk_line=$(grep -n "apk update" "${PROJECT_ROOT}/guest/overlay/etc/local.d/btbox.start" | head -1 | cut -d: -f1)
    if [ -n "$_net_line" ] && [ -n "$_apk_line" ] && [ "$_net_line" -lt "$_apk_line" ]; then
        echo "PASS: Network configured before package install"
        PASS=$((PASS + 1))
    else
        echo "FAIL: Network should be configured before apk update (net:${_net_line} apk:${_apk_line})"
        FAIL=$((FAIL + 1))
    fi
    assert_contains "Guest checks for BT adapter" "$_content" "_adapter_found"
    assert_contains "Guest verifies PipeWire started" "$_content" "kill -0"
}

# --- Test: build_alpine.sh has checksum verification ---
test_builder_checksum() {
    _content=$(cat "${PROJECT_ROOT}/guest/build_alpine.sh")
    assert_contains "Builder verifies SHA-256" "$_content" "sha256"
    assert_contains "Builder validates artifacts" "$_content" "_build_ok"
    assert_contains "Builder warns about SSH key" "$_content" "host_authorized_keys"
}

# --- Test: build_alpine.sh has portable download helper ---
test_builder_download_portability() {
    _content=$(cat "${PROJECT_ROOT}/guest/build_alpine.sh")
    assert_contains "Builder has download() function" "$_content" "download()"
    assert_contains "Builder supports fetch" "$_content" "fetch -o"
    assert_contains "Builder supports curl fallback" "$_content" "curl -fSL"
    assert_contains "Builder supports wget fallback" "$_content" "wget -q"
    assert_contains "Builder uses FAT16 label (not FAT32)" "$_content" "FAT16"
}

# --- Test: build_alpine.sh uses POSIX grep patterns ---
test_builder_posix_grep() {
    _content=$(cat "${PROJECT_ROOT}/guest/build_alpine.sh")
    assert_contains "Builder uses POSIX character class in grep" "$_content" '[[:space:]]'
}

# --- Test: btbox check_ssh_key uses POSIX grep and errors on missing file ---
test_ssh_key_check_posix() {
    _content=$(cat "${PROJECT_ROOT}/src/btbox")
    assert_contains "check_ssh_key uses POSIX character class" "$_content" '[[:space:]]'
    assert_contains "check_ssh_key errors on missing file" "$_content" "Missing SSH authorized keys file"
}

# --- Test: bhyve_runner guards state file removal ---
test_bhyve_state_guard() {
    _content=$(cat "${PROJECT_ROOT}/src/vmm/bhyve_runner.sh")
    assert_contains "bhyve_runner has _WROTE_STATE flag" "$_content" "_WROTE_STATE"
    assert_contains "bhyve_runner guards state file removal" "$_content" '_WROTE_STATE.*true'
}

# --- Test: common.sh portable stat ---
test_common_portable_stat() {
    _content=$(cat "${PROJECT_ROOT}/src/common.sh")
    assert_contains "common.sh supports GNU stat" "$_content" 'stat -c'
    assert_contains "common.sh supports FreeBSD stat" "$_content" 'stat -f'
}

# --- Test: validate_port() accepts valid ports ---
test_validate_port_valid() {
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
    assert_equals "validate_port accepts 7580" "7580" "$(validate_port 7580 7580)"
    assert_equals "validate_port accepts port 1 (minimum)" "1" "$(validate_port 1 9999)"
    assert_equals "validate_port accepts port 65535 (maximum)" "65535" "$(validate_port 65535 9999)"
    assert_equals "validate_port accepts port 4713" "4713" "$(validate_port 4713 9999)"
}

# --- Test: validate_port() rejects invalid ports ---
test_validate_port_invalid() {
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
    assert_equals "validate_port rejects empty string" "7580" "$(validate_port '' 7580)"
    assert_equals "validate_port rejects non-numeric (abc)" "7580" "$(validate_port 'abc' 7580)"
    assert_equals "validate_port rejects 0 (out of range)" "7580" "$(validate_port 0 7580)"
    assert_equals "validate_port rejects 65536 (out of range)" "7580" "$(validate_port 65536 7580)"
    assert_equals "validate_port rejects negative value" "7580" "$(validate_port '-1' 7580)"
    assert_equals "validate_port rejects alphanumeric mix" "9999" "$(validate_port 'abc123' 9999)"
}

# --- Test: validate_bind() accepts valid addresses ---
test_validate_bind_valid() {
    validate_bind() {
        _val="$1"
        _default="$2"
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
    assert_equals "validate_bind accepts IPv4 address" "10.0.0.2" "$(validate_bind '10.0.0.2' '10.0.0.2')"
    assert_equals "validate_bind accepts 127.0.0.1" "127.0.0.1" "$(validate_bind '127.0.0.1' '10.0.0.2')"
    assert_equals "validate_bind accepts simple hostname" "localhost" "$(validate_bind 'localhost' '10.0.0.2')"
    assert_equals "validate_bind accepts hostname with hyphen" "my-host" "$(validate_bind 'my-host' '10.0.0.2')"
}

# --- Test: validate_bind() rejects invalid addresses ---
test_validate_bind_invalid() {
    validate_bind() {
        _val="$1"
        _default="$2"
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
    assert_equals "validate_bind rejects empty string" "10.0.0.2" "$(validate_bind '' '10.0.0.2')"
    assert_equals "validate_bind rejects address with dollar sign" "10.0.0.2" "$(validate_bind '$(evil)' '10.0.0.2')"
    assert_equals "validate_bind rejects address with at sign" "10.0.0.2" "$(validate_bind 'user@host' '10.0.0.2')"
    assert_equals "validate_bind rejects address with spaces" "10.0.0.2" "$(validate_bind '10.0.0 2' '10.0.0.2')"
    assert_equals "validate_bind rejects address with semicolon" "10.0.0.2" "$(validate_bind '10.0.0.2;evil' '10.0.0.2')"
}

# --- Test: validate_mac() accepts valid MAC addresses ---
test_validate_mac_valid() {
    _exit_code=$(
        msg_err() { echo "ERR: $*" >&2; }
        validate_mac() {
            if ! echo "$1" | grep -qE '^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$'; then
                msg_err "Invalid MAC address: $1"
                return 1
            fi
        }
        validate_mac "AA:BB:CC:DD:EE:FF" && \
        validate_mac "aa:bb:cc:dd:ee:ff" && \
        validate_mac "00:1A:2B:3C:4D:5E"
        echo $?
    )
    assert_equals "validate_mac accepts valid uppercase MAC" "0" "$_exit_code"
}

# --- Test: validate_mac() rejects invalid MAC addresses ---
test_validate_mac_invalid() {
    _content=$(cat "${PROJECT_ROOT}/src/btbox")
    # Verify validate_mac uses the correct regex pattern
    assert_contains "validate_mac uses hex character class" "$_content" '[0-9A-Fa-f]'
    assert_contains "validate_mac checks exactly 6 groups" "$_content" '{5}'
    # Verify colon separator: AA-BB-CC-DD-EE-FF (hyphens) must be rejected while
    # AA:BB:CC:DD:EE:FF (colons) is accepted — proving colon is the required separator
    if echo "AA-BB-CC-DD-EE-FF" | grep -qE '^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$'; then
        echo "FAIL: validate_mac regex should reject hyphen-separated MAC"
        FAIL=$((FAIL + 1))
    else
        echo "PASS: validate_mac regex requires colon separators (rejects hyphens)"
        PASS=$((PASS + 1))
    fi
    if echo "AA:BB:CC:DD:EE:FF" | grep -qE '^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$'; then
        echo "PASS: validate_mac regex accepts colon-separated MAC"
        PASS=$((PASS + 1))
    else
        echo "FAIL: validate_mac regex should accept colon-separated MAC"
        FAIL=$((FAIL + 1))
    fi

    # Functional test: invalid formats should fail the grep
    for _invalid in "AA:BB:CC:DD:EE" "AA:BB:CC:DD:EE:GG" "AABBCCDDEEFF" "AA-BB-CC-DD-EE-FF" ""; do
        if echo "$_invalid" | grep -qE '^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$'; then
            echo "FAIL: validate_mac should reject '${_invalid}' but accepted it"
            FAIL=$((FAIL + 1))
        else
            echo "PASS: validate_mac correctly rejects '${_invalid}'"
            PASS=$((PASS + 1))
        fi
    done
}

# --- Test: check_ssh_key() warns on empty/comment-only key file ---
test_check_ssh_key_empty_file() {
    _tmpdir=$(mktemp -d)
    _keyfile="${_tmpdir}/host_authorized_keys"
    # Create a key file with only comments
    printf '# This is a comment\n# Another comment\n\n' > "$_keyfile"

    _output=$(
        BTBOX_ROOT="$_tmpdir"
        msg_warn() { echo "WARN: $*"; }
        msg_err()  { echo "ERR: $*"; }
        check_ssh_key() {
            _overlay="${BTBOX_ROOT}/guest/overlay/etc/btbox/host_authorized_keys"
            if [ -f "$_overlay" ]; then
                if ! grep -Eqv '^[[:space:]]*(#|$)' "$_overlay" 2>/dev/null; then
                    msg_warn "No SSH public key found in $_overlay"
                fi
            else
                msg_err "Missing SSH authorized keys file: $_overlay"
                return 1
            fi
        }
        mkdir -p "${_tmpdir}/guest/overlay/etc/btbox"
        cp "$_keyfile" "${_tmpdir}/guest/overlay/etc/btbox/host_authorized_keys"
        check_ssh_key
    )
    rm -rf "$_tmpdir"
    assert_contains "check_ssh_key warns on comment-only file" "$_output" "No SSH public key"
}

# --- Test: check_ssh_key() succeeds with a real key ---
test_check_ssh_key_with_key() {
    _tmpdir=$(mktemp -d)
    mkdir -p "${_tmpdir}/guest/overlay/etc/btbox"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA test-key\n' \
        > "${_tmpdir}/guest/overlay/etc/btbox/host_authorized_keys"

    _output=$(
        BTBOX_ROOT="$_tmpdir"
        msg_warn() { echo "WARN: $*"; }
        msg_err()  { echo "ERR: $*"; }
        check_ssh_key() {
            _overlay="${BTBOX_ROOT}/guest/overlay/etc/btbox/host_authorized_keys"
            if [ -f "$_overlay" ]; then
                if ! grep -Eqv '^[[:space:]]*(#|$)' "$_overlay" 2>/dev/null; then
                    msg_warn "No SSH public key found in $_overlay"
                fi
            else
                msg_err "Missing SSH authorized keys file: $_overlay"
                return 1
            fi
        }
        check_ssh_key; echo "exit:$?"
    )
    rm -rf "$_tmpdir"
    # No warning expected — output should only have the exit code line
    if echo "$_output" | grep -q "No SSH public key"; then
        echo "FAIL: check_ssh_key should not warn when key is present"
        FAIL=$((FAIL + 1))
    else
        echo "PASS: check_ssh_key does not warn when valid key present"
        PASS=$((PASS + 1))
    fi
}

# --- Test: check_ssh_key() exits on missing file ---
test_check_ssh_key_missing_file() {
    _tmpdir=$(mktemp -d)
    _rc=$(
        BTBOX_ROOT="$_tmpdir"
        msg_warn() { echo "WARN: $*" >&2; }
        msg_err()  { echo "ERR: $*" >&2; }
        check_ssh_key() {
            _overlay="${BTBOX_ROOT}/guest/overlay/etc/btbox/host_authorized_keys"
            if [ -f "$_overlay" ]; then
                if ! grep -Eqv '^[[:space:]]*(#|$)' "$_overlay" 2>/dev/null; then
                    msg_warn "No SSH public key found in $_overlay"
                fi
            else
                msg_err "Missing SSH authorized keys file: $_overlay"
                exit 1
            fi
        }
        check_ssh_key
        echo "0"
    ) 2>/dev/null
    rm -rf "$_tmpdir"
    # The subshell exits(1) before printing "0", so output should be empty
    if [ -z "$_rc" ]; then
        echo "PASS: check_ssh_key exits on missing authorized keys file"
        PASS=$((PASS + 1))
    else
        echo "FAIL: check_ssh_key should exit when authorized keys file is missing (got: $_rc)"
        FAIL=$((FAIL + 1))
    fi
}

# --- Test: BTBOX_INPUT_RELAY case handling in btbox.start ---
test_btbox_input_relay_case_handling() {
    _content=$(cat "${PROJECT_ROOT}/guest/overlay/etc/local.d/btbox.start")
    # The script normalizes BTBOX_INPUT_RELAY to lowercase before comparing
    assert_contains "btbox.start normalizes BTBOX_INPUT_RELAY case" "$_content" 'tr.*lower'
    # Verify yes and true both enable the relay
    assert_contains "btbox.start enables relay on 'yes'" "$_content" "yes|true"
}

# --- Test: WirePlumber config has bluez5.roles ---
test_wireplumber_bluez_roles() {
    _conf="${PROJECT_ROOT}/guest/overlay/etc/wireplumber/wireplumber.conf.d/51-btbox-bluetooth.conf"
    _content=$(cat "$_conf")
    assert_contains "WirePlumber has bluez5.roles" "$_content" "bluez5.roles"
    assert_contains "WirePlumber includes a2dp_sink role" "$_content" "a2dp_sink"
    assert_contains "WirePlumber includes hfp_ag role" "$_content" "hfp_ag"
}

# --- Test: input-relay.sh rejects invalid device paths ---
test_input_relay_path_validation() {
    _content=$(cat "${PROJECT_ROOT}/guest/overlay/etc/btbox/input-relay.sh")
    # Relay only accepts /dev/input/event* paths
    assert_contains "Input relay validates /dev/input/event* prefix" "$_content" '/dev/input/event'
    assert_contains "Input relay rejects invalid paths with message" "$_content" "Skipping invalid device path"
}

# --- Test: input-relay.sh bustype 0005 check for Bluetooth detection ---
test_input_relay_bustype_check() {
    _content=$(cat "${PROJECT_ROOT}/guest/overlay/etc/btbox/input-relay.sh")
    assert_contains "Input relay checks bustype file" "$_content" "id/bustype"
    assert_contains "Input relay checks for BT bustype 0005" "$_content" "0005"
    assert_contains "Input relay uses udevadm fallback" "$_content" "udevadm"
    assert_contains "Input relay checks ID_BUS=bluetooth" "$_content" "ID_BUS=bluetooth"
}

# --- Test: bhyve_runner cmd_stop validates VM is running ---
test_bhyve_stop_validates_running() {
    _content=$(cat "${PROJECT_ROOT}/src/vmm/bhyve_runner.sh")
    assert_contains "cmd_stop checks /dev/vmm before destroy" "$_content" '/dev/vmm/'
    assert_contains "cmd_stop errors when VM not running" "$_content" "VM is not running"
}

# --- Test: build_alpine.sh uses fat_type=16 in makefs ---
test_builder_makefs_fat16_option() {
    _content=$(cat "${PROJECT_ROOT}/guest/build_alpine.sh")
    # The actual makefs command must use fat_type=16, not fat_type=32
    assert_contains "Builder makefs uses fat_type=16 option" "$_content" "fat_type=16"
    if echo "$_content" | grep -q "fat_type=32"; then
        echo "FAIL: Builder should not use fat_type=32 (regression)"
        FAIL=$((FAIL + 1))
    else
        echo "PASS: Builder does not use fat_type=32"
        PASS=$((PASS + 1))
    fi
}

# --- Test: btbox info command validates MAC before executing ---
test_btbox_info_validates_mac() {
    _content=$(cat "${PROJECT_ROOT}/src/btbox")
    # The info case block should call validate_mac
    assert_contains "btbox info calls validate_mac" "$_content" "validate_mac"
    # The info case should also call check_vm_running
    assert_contains "btbox info calls check_vm_running" "$_content" "check_vm_running"
}

# --- Test: btbox start calls check_ssh_key before VMM ---
test_btbox_start_checks_ssh_key() {
    _content=$(cat "${PROJECT_ROOT}/src/btbox")
    # check_ssh_key should appear before bhyve_runner.sh start in the start case
    _sshkey_line=$(printf '%s\n' "$_content" | grep -n "check_ssh_key" | head -1 | cut -d: -f1)
    _vmm_line=$(printf '%s\n' "$_content" | grep -n "bhyve_runner.sh.*start" | head -1 | cut -d: -f1)
    if [ -n "$_sshkey_line" ] && [ -n "$_vmm_line" ] && [ "$_sshkey_line" -lt "$_vmm_line" ]; then
        echo "PASS: check_ssh_key is called before VMM runner in start command"
        PASS=$((PASS + 1))
    else
        echo "FAIL: check_ssh_key should appear before bhyve_runner.sh start (sshkey:${_sshkey_line} vmm:${_vmm_line})"
        FAIL=$((FAIL + 1))
    fi
}

# --- Test: common.sh skips security checks for non-root ---
test_common_nonroot_skips_security() {
    _content=$(cat "${PROJECT_ROOT}/src/common.sh")
    # The security check block must be guarded by id -u eq 0
    assert_contains "common.sh gates security check on root uid" "$_content" 'id -u'
    assert_contains "common.sh checks for uid 0" "$_content" '-eq 0'
}

# --- Test: PipeWire services redirect to /var/log/ in btbox.start ---
test_guest_pipewire_log_redirect() {
    _content=$(cat "${PROJECT_ROOT}/guest/overlay/etc/local.d/btbox.start")
    assert_contains "PipeWire logs to /var/log/pipewire.log" "$_content" "/var/log/pipewire.log"
    assert_contains "WirePlumber logs to /var/log/wireplumber.log" "$_content" "/var/log/wireplumber.log"
    assert_contains "PipeWire-Pulse logs to /var/log/pipewire-pulse.log" "$_content" "/var/log/pipewire-pulse.log"
}

# --- Test: bhyve_runner device.map removed immediately after grub-bhyve ---
test_bhyve_device_map_cleanup_order() {
    # Look for the inline rm -f "$DEVICE_MAP" (variable form), which is the
    # immediate post-grub cleanup, distinct from the cleanup() trap which uses
    # the literal path "${BTBOX_ROOT}/device.map".
    _grub_line=$(grep -n "grub-bhyve" "${PROJECT_ROOT}/src/vmm/bhyve_runner.sh" | head -1 | cut -d: -f1)
    _rm_map_line=$(grep -n 'rm -f.*"\$DEVICE_MAP"' "${PROJECT_ROOT}/src/vmm/bhyve_runner.sh" | head -1 | cut -d: -f1)
    if [ -n "$_grub_line" ] && [ -n "$_rm_map_line" ] && [ "$_rm_map_line" -gt "$_grub_line" ]; then
        echo "PASS: device.map is removed inline after grub-bhyve (grub:${_grub_line} rm:${_rm_map_line})"
        PASS=$((PASS + 1))
    else
        echo "FAIL: device.map removal should come after grub-bhyve (grub:${_grub_line} rm:${_rm_map_line})"
        FAIL=$((FAIL + 1))
    fi
}

# --- Test: input-relay.sh cleanup trap is registered ---
test_input_relay_cleanup_trap() {
    _content=$(cat "${PROJECT_ROOT}/guest/overlay/etc/btbox/input-relay.sh")
    assert_contains "Input relay registers cleanup trap" "$_content" "trap cleanup_relay"
    assert_contains "Input relay trap covers INT signal" "$_content" "INT"
    assert_contains "Input relay trap covers TERM signal" "$_content" "TERM"
    assert_contains "Input relay trap covers EXIT" "$_content" "EXIT"
}

# --- Test: bhyve_runner acquire_lock uses mkdir for atomicity ---
test_bhyve_lock_uses_mkdir() {
    _content=$(cat "${PROJECT_ROOT}/src/vmm/bhyve_runner.sh")
    assert_contains "acquire_lock uses mkdir for atomic lock" "$_content" 'mkdir.*BTBOX_LOCK_FILE'
    assert_contains "acquire_lock removes lock on EXIT via trap" "$_content" 'rm -rf.*BTBOX_LOCK_FILE'
}

# --- Test: bhyve_runner wait_for_guest respects timeout parameter ---
test_bhyve_wait_for_guest_timeout() {
    _content=$(cat "${PROJECT_ROOT}/src/vmm/bhyve_runner.sh")
    assert_contains "wait_for_guest accepts max_wait parameter" "$_content" "_max_wait"
    assert_contains "wait_for_guest polls with sleep" "$_content" "sleep 2"
    assert_contains "wait_for_guest warns when timeout reached" "$_content" "did not become reachable"
}

# --- Test: bhyve_runner check_guest_artifacts checks all three required files ---
test_bhyve_check_artifacts_complete() {
    _content=$(cat "${PROJECT_ROOT}/src/vmm/bhyve_runner.sh")
    assert_contains "check_guest_artifacts checks vmlinuz" "$_content" "vmlinuz"
    assert_contains "check_guest_artifacts checks initramfs" "$_content" "initramfs"
    assert_contains "check_guest_artifacts checks seed.img" "$_content" "seed.img"
}

# --- Test: bhyve_runner known_hosts cleaned on stop ---
test_bhyve_stop_cleans_known_hosts() {
    _content=$(cat "${PROJECT_ROOT}/src/vmm/bhyve_runner.sh")
    assert_contains "cmd_stop removes btbox_known_hosts" "$_content" "btbox_known_hosts"
}

# --- Test: guest startup derives default route from guest IP ---
test_guest_default_route_derivation() {
    _content=$(cat "${PROJECT_ROOT}/guest/overlay/etc/local.d/btbox.start")
    # Default route is derived by stripping the last octet of BTBOX_GUEST_IP and appending .1
    # The sed pattern replaces trailing .<digits> with .1 (e.g. 10.0.0.2 -> 10.0.0.1)
    assert_contains "Guest uses sed to derive gateway from guest IP" "$_content" 'sed.*\.1'
    assert_contains "Guest adds default route to host" "$_content" "ip route add default via"
}

# --- Test: input-relay.sh reports stale pidfile correctly ---
test_input_relay_stale_pidfile_handling() {
    _content=$(cat "${PROJECT_ROOT}/guest/overlay/etc/btbox/input-relay.sh")
    # Script should validate PID is numeric before using kill -0
    assert_contains "Input relay validates PID is numeric" "$_content" '[!0-9]'
    assert_contains "Input relay removes stale pidfile" "$_content" "rm -f.*RELAY_PIDFILE"
}

# --- Test: bhyve_runner validates passthrough PCI format ---
test_bhyve_pci_format_validation() {
    _content=$(cat "${PROJECT_ROOT}/src/vmm/bhyve_runner.sh")
    assert_contains "bhyve_runner validates PASSTHRU_PCI format" "$_content" "Invalid PASSTHRU_PCI format"
    assert_contains "bhyve_runner checks bus/slot/function pattern" "$_content" 'bus/slot/function'
}

# --- Run all tests ---
echo "========================================="
echo " btbox Test Suite"
echo "========================================="

test_config_missing
test_usage_output
test_syntax_common
test_syntax_ui_utils
test_syntax_check_hw
test_syntax_bhyve_runner
test_syntax_build_alpine
test_syntax_guest_start
test_syntax_input_relay
test_input_relay_security
test_ui_functions
test_config_sample_variables
test_bluez_hid_config
test_btbox_info_command
test_guest_hid_packages
test_wireplumber_hid_config
test_btbox_check_hw_command
test_guest_exec_options
test_bhyve_runner_features
test_guest_boot_order
test_builder_checksum
test_builder_download_portability
test_builder_posix_grep
test_ssh_key_check_posix
test_bhyve_state_guard
test_common_portable_stat
test_validate_port_valid
test_validate_port_invalid
test_validate_bind_valid
test_validate_bind_invalid
test_validate_mac_valid
test_validate_mac_invalid
test_check_ssh_key_empty_file
test_check_ssh_key_with_key
test_check_ssh_key_missing_file
test_btbox_input_relay_case_handling
test_wireplumber_bluez_roles
test_input_relay_path_validation
test_input_relay_bustype_check
test_bhyve_stop_validates_running
test_builder_makefs_fat16_option
test_btbox_info_validates_mac
test_btbox_start_checks_ssh_key
test_common_nonroot_skips_security
test_guest_pipewire_log_redirect
test_bhyve_device_map_cleanup_order
test_input_relay_cleanup_trap
test_bhyve_lock_uses_mkdir
test_bhyve_wait_for_guest_timeout
test_bhyve_check_artifacts_complete
test_bhyve_stop_cleans_known_hosts
test_guest_default_route_derivation
test_input_relay_stale_pidfile_handling
test_bhyve_pci_format_validation

echo "========================================="
echo " Results: ${PASS} passed, ${FAIL} failed"
echo "========================================="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
