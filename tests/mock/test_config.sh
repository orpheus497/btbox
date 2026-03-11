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
}

# --- Test: WirePlumber config handles Bluetooth audio and input nodes ---
test_wireplumber_hid_config() {
    _conf="${PROJECT_ROOT}/guest/overlay/etc/wireplumber/wireplumber.conf.d/51-btbox-bluetooth.conf"
    _content=$(cat "$_conf")
    assert_contains "WirePlumber has input node rule" "$_content" "bluez_input"
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

echo "========================================="
echo " Results: ${PASS} passed, ${FAIL} failed"
echo "========================================="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
