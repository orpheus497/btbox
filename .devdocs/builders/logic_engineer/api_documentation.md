# API Documentation: Internal Logic

## Guest Construction (`guest/build_alpine.sh`)

The builder script performs the following actions:
1.  **Fetcher**: Downloads Alpine Linux `virt` ISO.
2.  **Extractor**: Extracts `vmlinuz-virt` (Kernel) and `initramfs-virt` (Init RAM Disk).
3.  **Overlay Builder**: Packs the contents of `guest/overlay/` into a standard Alpine overlay file (`btbox.apkovl.tar.gz`).
4.  **Seed Generator**: Uses `makefs` to create a generic FAT32 disk image (`seed.img`) containing the overlay. This ensures Alpine finds the configuration on boot without needing a network fetch immediately.

## Hypervisor Control (`src/vmm/bhyve_runner.sh`)

The runner handles the Bhyve lifecycle:
1.  **Module Loading**: Ensures `vmm`, `nmdm` are loaded.
2.  **Network**: Creates a `tap` interface (Bridge logic pending).
3.  **Bootloader**: Uses `grub-bhyve` to load the Linux kernel in direct-boot mode.
4.  **Execution**: Launches `bhyve` with:
    *   `-s 0:0,hostbridge`
    *   `-s 2:0,virtio-net` (Network)
    *   `-s 3:0,virtio-blk` (The `seed.img` config disk)
    *   `-s 6,passthru` (The USB controller, if configured)

## Configuration Schema (`btbox.conf`)
*   `PASSTHRU_PCI`: BDF format (Bus/Device/Function) of the USB controller.
*   `VM_RAM`: Memory size (e.g., 128M).
*   `VM_CPUS`: VCPU count.
