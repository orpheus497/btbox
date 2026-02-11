# Architecture & Structure Plan

## Project: btbox

### Core Concept
A Bhyve VM wrapper that runs a minimal Linux guest to handle Bluetooth hardware, bridging audio streams back to the host system.

### Directory Structure
```
/
├── .devdocs/               # Agent Documentation
├── conf/                   # Configuration templates
│   └── btbox.conf.sample   # Sample config
├── guest/                  # Guest OS generation
│   ├── Alpine/             # Alpine Linux build scripts
│   └── overlay/            # Files to copy into guest
├── src/                    # Source scripts
│   ├── btbox               # Main CLI wrapper
│   └── vmm/                # Bhyve management logic
├── Makefile                # Build/Install system
└── README.md
```

### Technical Decisions
1.  **Guest OS**: Alpine Linux. Reason: Extremely small footprint (<50MB RAM possible), similar to `wifibox`.
2.  **Audio Transport**: PulseAudio simple protocol or PipeWire native TCP. The Host (FreeBSD) will run `pulseaudio` or `pipewire-pulse` receiving a stream from the Guest.
3.  **Hardware Access**: PCI Passthrough of the USB Controller handling the Bluetooth device.
    *   *Constraint*: This requires the user to pass a whole USB controller.
4.  **Network**: `tap` interface bridged to host for audio traffic.

### Configuration (`btbox.conf`)
*   `VM_RAM`: Memory allocation (default 128MB).
*   `PASSTHRU_PCI`: The PCI address of the USB controller.
*   `AUDIO_PORT`: Port for audio stream.

### Dependencies (FreeBSD)
*   `bhyve`
*   `grub2-bhyve` or `bhyve-firmware` (uefi)
*   `socat` (potentially for socket bridging)
