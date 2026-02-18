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
    assert_equals "GUEST_IP is set" "10.0.0.2" "$GUEST_IP"
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
test_ui_functions
test_config_sample_variables

echo "========================================="
echo " Results: ${PASS} passed, ${FAIL} failed"
echo "========================================="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
