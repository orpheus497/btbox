#!/bin/sh
##Script function and purpose: Automates the downloading and construction of the Alpine Linux guest image and configuration overlay.
#
# btbox - Alpine Guest Builder
#

set -e

# Resolve the directory where this script lives (guest/)
GUEST_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load Builder Config
if [ -f "${GUEST_SCRIPT_DIR}/builder.conf" ]; then
    . "${GUEST_SCRIPT_DIR}/builder.conf"
fi

# Defaults if conf missing
ALPINE_VERSION=${ALPINE_VERSION:-"3.21.2"}
ALPINE_MAJOR=${ALPINE_MAJOR:-"v3.21"}
MIRROR=${MIRROR:-"https://dl-cdn.alpinelinux.org/alpine"}
ARCH=${ARCH:-"x86_64"}

ISO_NAME="alpine-virt-${ALPINE_VERSION}-${ARCH}.iso"
ISO_URL="${MIRROR}/${ALPINE_MAJOR}/releases/${ARCH}/${ISO_NAME}"
SHA256_URL="${MIRROR}/${ALPINE_MAJOR}/releases/${ARCH}/${ISO_NAME}.sha256"

WORK_DIR="${GUEST_SCRIPT_DIR}/build"
OUTPUT_DIR="${GUEST_SCRIPT_DIR}/output"
OVERLAY_DIR="${GUEST_SCRIPT_DIR}/overlay"

mkdir -p "${WORK_DIR}" "${OUTPUT_DIR}"

##Function purpose: Portable file downloader — uses fetch (FreeBSD), curl, or wget.
download() {
    _url="$1"
    _out="$2"
    if command -v fetch >/dev/null 2>&1; then
        fetch -o "$_out" "$_url"
    elif command -v curl >/dev/null 2>&1; then
        curl -fSL -o "$_out" "$_url"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$_out" "$_url"
    else
        echo ">> ERROR: No download tool found (fetch, curl, or wget required)."
        exit 1
    fi
}

##Step purpose: Warn if no SSH public key is configured.
AUTH_KEYS="${OVERLAY_DIR}/etc/btbox/host_authorized_keys"
if [ -f "$AUTH_KEYS" ]; then
    if ! grep -Eqv '^[[:space:]]*(#|$)' "$AUTH_KEYS" 2>/dev/null; then
        echo ">> WARNING: No SSH public key found in ${AUTH_KEYS}"
        echo ">>          Device management commands (scan/pair/connect) require SSH access."
        echo ">>          Add your host key:  cat ~/.ssh/id_ed25519.pub >> ${AUTH_KEYS}"
        echo ""
    fi
else
    echo ">> WARNING: ${AUTH_KEYS} not found. SSH access to guest will not work."
fi

##Step purpose: Check for or download the Alpine ISO.
echo ">> Checking for Alpine ISO..."
##Condition purpose: Download only if missing.
if [ ! -f "${WORK_DIR}/${ISO_NAME}" ]; then
    echo ">> Downloading ${ISO_NAME}..."
    download "${ISO_URL}" "${WORK_DIR}/${ISO_NAME}"
else
    echo ">> ISO present."
fi

##Step purpose: Verify ISO integrity with SHA-256 checksum.
echo ">> Verifying ISO checksum..."
if download "${SHA256_URL}" "${WORK_DIR}/${ISO_NAME}.sha256" 2>/dev/null; then
    _expected_hash=$(awk '{print $1}' "${WORK_DIR}/${ISO_NAME}.sha256")
    if command -v sha256 >/dev/null 2>&1; then
        # FreeBSD sha256
        _actual_hash=$(sha256 -q "${WORK_DIR}/${ISO_NAME}")
    elif command -v sha256sum >/dev/null 2>&1; then
        # GNU/Linux sha256sum
        _actual_hash=$(sha256sum "${WORK_DIR}/${ISO_NAME}" | awk '{print $1}')
    else
        echo ">> WARNING: No sha256 tool found. Skipping checksum verification."
        _expected_hash=""
        _actual_hash=""
    fi
    if [ -n "$_expected_hash" ] && [ "$_expected_hash" != "$_actual_hash" ]; then
        echo ">> ERROR: SHA-256 checksum mismatch!"
        echo ">>   Expected: ${_expected_hash}"
        echo ">>   Actual:   ${_actual_hash}"
        echo ">> Delete ${WORK_DIR}/${ISO_NAME} and re-download."
        exit 1
    elif [ -n "$_expected_hash" ]; then
        echo ">> Checksum verified."
    fi
else
    echo ">> WARNING: Could not fetch checksum file. Skipping verification."
fi

##Step purpose: Extract Kernel and Initramfs from ISO.
echo ">> Extracting Kernel and Initramfs..."
# We use tar to extract from ISO (ISO 9660 is often supported by bsdtar)
tar -xf "${WORK_DIR}/${ISO_NAME}" -C "${WORK_DIR}" boot/vmlinuz-virt boot/initramfs-virt

##Action purpose: Move artifacts to output directory.
mv "${WORK_DIR}/boot/vmlinuz-virt" "${OUTPUT_DIR}/vmlinuz"
mv "${WORK_DIR}/boot/initramfs-virt" "${OUTPUT_DIR}/initramfs"

##Step purpose: Create the apkovl configuration overlay.
echo ">> Creating Configuration Overlay (apkovl)..."
# Create a tar.gz of the overlay directory
# The structure inside tar must be etc/...
# We enter the overlay directory to tar relatively
tar -C "${OVERLAY_DIR}" -czf "${OUTPUT_DIR}/btbox.apkovl.tar.gz" .

##Step purpose: Create the Seed Image for config injection.
echo ">> Creating Seed Image (FAT16)..."
# Create a temporary directory for the seed content
SEED_DIR="${WORK_DIR}/seed"
mkdir -p "${SEED_DIR}"
cp "${OUTPUT_DIR}/btbox.apkovl.tar.gz" "${SEED_DIR}/"

# Create a FAT16 image — use makefs with FreeBSD-compatible options
if command -v makefs >/dev/null 2>&1; then
    makefs -t msdos -o fat_type=16 -s 10m "${OUTPUT_DIR}/seed.img" "${SEED_DIR}"
elif command -v truncate >/dev/null 2>&1 && command -v mkfs.fat >/dev/null 2>&1; then
    # Fallback for Linux build hosts (CI environment)
    truncate -s 10M "${OUTPUT_DIR}/seed.img"
    mkfs.fat -F 16 "${OUTPUT_DIR}/seed.img"
    # Copy files using mcopy if available, otherwise warn
    if command -v mcopy >/dev/null 2>&1; then
        mcopy -i "${OUTPUT_DIR}/seed.img" "${SEED_DIR}/btbox.apkovl.tar.gz" ::/
    else
        echo ">> WARNING: mcopy not found. Seed image created but overlay not injected."
        echo ">>          Install mtools or use FreeBSD makefs instead."
    fi
else
    echo ">> ERROR: No tool to create FAT image (makefs or mkfs.fat)."
    exit 1
fi

##Step purpose: Validate build artifacts.
echo ">> Validating build artifacts..."
_build_ok=true
for _artifact in vmlinuz initramfs btbox.apkovl.tar.gz seed.img; do
    if [ ! -f "${OUTPUT_DIR}/${_artifact}" ]; then
        echo ">> ERROR: Missing artifact: ${OUTPUT_DIR}/${_artifact}"
        _build_ok=false
    fi
done
if [ "$_build_ok" = "false" ]; then
    echo ">> Build FAILED — one or more artifacts missing."
    exit 1
fi

##Step purpose: Report completion.
echo ">> Guest Build Complete."
echo "   Kernel:    ${OUTPUT_DIR}/vmlinuz"
echo "   Initramfs: ${OUTPUT_DIR}/initramfs"
echo "   Overlay:   ${OUTPUT_DIR}/btbox.apkovl.tar.gz"
echo "   Seed Img:  ${OUTPUT_DIR}/seed.img"
