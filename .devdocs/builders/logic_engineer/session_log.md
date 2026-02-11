# Session Log

## 2026-02-12
*   **Action**: Implemented Guest Builder and Host Runner.
*   **Files Created**:
    *   `guest/build_alpine.sh`
    *   `guest/overlay/etc/local.d/btbox.start`
    *   `guest/overlay/etc/bluetooth/main.conf`
    *   `guest/overlay/etc/pipewire/pipewire-pulse.conf`
    *   `src/btbox`
    *   `src/vmm/bhyve_runner.sh`
*   **Decisions**:
    *   Used "Seed Image" strategy (FAT32 loopback) to inject `apkovl` into the guest. This avoids complex network booting or ISO modification.
    *   Selected `grub-bhyve` for direct kernel booting of Alpine.
    *   configured PipeWire to listen on TCP 4713 to act as a PulseAudio server for the host.
