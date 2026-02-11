# btbox

**btbox** is a FreeBSD utility designed to provide modern Bluetooth Audio support (A2DP, HFP, LC3) by leveraging a lightweight Linux guest (Alpine) running in a Bhyve virtual machine.

Inspired by [wifibox](https://github.com/pgj/freebsd-wifibox), `btbox` passes the USB controller responsible for Bluetooth to the guest, where BlueZ and PipeWire handle the protocol stack, bridging high-quality audio back to the FreeBSD host via network.

## Architecture

*   **Hypervisor:** Bhyve
*   **Guest:** Alpine Linux
*   **Audio Bridge:** PipeWire/PulseAudio over TCP (Virtual Ethernet)

## Prerequisites

*   FreeBSD 13.0+
*   CPU with VT-x/AMD-V and IOMMU (VT-d/AMD-Vi) support.
*   A dedicated USB controller (or PCI card) for the Bluetooth device to be passed through.

You can verify your hardware support by running:
```bash
sh src/check_hw.sh
```

## Status

**Current Version:** 0.1.0-alpha

*   [x] Project Initialization
*   [x] Guest Image Builder (Alpine)
*   [x] Bhyve Hypervisor Runner
*   [x] Security Hardening
*   [x] CLI UX/Branding
*   [x] CI/CD Workflow
*   [ ] Integration Testing on Bare Metal

## Installation

*(Coming Soon)*

## Configuration

Copy `conf/btbox.conf.sample` to `/usr/local/etc/btbox.conf` and edit it to specify your PCI passthrough slot.

## License

BSD 2-Clause License
