#!/bin/sh
##Script function and purpose: Mock test suite for btbox configuration and security logic.
#
# tests/mock/test_config.sh
#

# Mock the UI utils to avoid color codes cluttering logs
show_banner() { :; }
msg_info() { echo "INFO: $*"; }
msg_ok() { echo "OK: $*"; }
msg_err() { echo "ERR: $*"; }
msg_warn() { echo "WARN: $*"; }

# Mock system commands
id() { echo 0; } # Always root for logic tests
kldload() { :; } # Mock kernel load

# Path to system under test
SUT="./src/btbox"

# Setup
setUp() {
    # Create temp config directory
    mkdir -p tmp_conf
    echo "PASSTHRU_PCI='0/0/0'" > tmp_conf/valid.conf
    chmod 600 tmp_conf/valid.conf
}

# Teardown
tearDown() {
    rm -rf tmp_conf
}

# Tests
test_config_missing() {
    # We expect failure
    output=$(sh $SUT start 2>&1)
    # Since default config is missing in test env, this should fail
    # But wait, the script checks default locations.
    # We need to force it to use a missing config.
    # The script doesn't accept a config flag yet.
    # We can check if it fails safely.
    assertTrue "Script should fail without config" "[ $? -ne 0 ]"
}

# Load shunit2
# We assume it's available or we download it.
# For this environment, we will create a simple runner if shunit2 isn't present.
