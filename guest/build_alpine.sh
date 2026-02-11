#!/bin/sh
##Script function and purpose: Automates the downloading and construction of the Alpine Linux guest image and configuration overlay.
#
# btbox - Alpine Guest Builder
#

set -e

ALPINE_VERSION="3.21.2"
ALPINE_MAJOR="v3.21"
MIRROR="https://dl-cdn.alpinelinux.org/alpine"
ARCH="x86_64"
ISO_NAME="alpine-virt-${ALPINE_VERSION}-${ARCH}.iso"
ISO_URL="${MIRROR}/${ALPINE_MAJOR}/releases/${ARCH}/${ISO_NAME}"

WORK_DIR="guest/build"
OUTPUT_DIR="guest/output"
OVERLAY_DIR="guest/overlay"

mkdir -p "${WORK_DIR}" "${OUTPUT_DIR}"

##Step purpose: Check for or download the Alpine ISO.
echo ">> Checking for Alpine ISO..."
##Condition purpose: Download only if missing.
if [ ! -f "${WORK_DIR}/${ISO_NAME}" ]; then
    echo ">> Downloading ${ISO_NAME}..."
    fetch -o "${WORK_DIR}/${ISO_NAME}" "${ISO_URL}"
else
    echo ">> ISO present."
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
echo ">> Creating Seed Image (FAT32)..."
# Create a temporary directory for the seed content
SEED_DIR="${WORK_DIR}/seed"
mkdir -p "${SEED_DIR}"
cp "${OUTPUT_DIR}/btbox.apkovl.tar.gz" "${SEED_DIR}/"

# Use makefs to create a FAT32 image
makefs -t msdos -s 10m "${OUTPUT_DIR}/seed.img" "${SEED_DIR}"

##Step purpose: Report completion.
echo ">> Guest Build Complete."
echo "   Kernel:    ${OUTPUT_DIR}/vmlinuz"
echo "   Initramfs: ${OUTPUT_DIR}/initramfs"
echo "   Overlay:   ${OUTPUT_DIR}/btbox.apkovl.tar.gz"
echo "   Seed Img:  ${OUTPUT_DIR}/seed.img"