# btbox (Bluetooth Box for FreeBSD)

**btbox** is a specialized virtualization wrapper designed to bring modern, high-fidelity Bluetooth Audio and device management to FreeBSD. By leveraging a lightweight Alpine Linux guest running under the Bhyve hypervisor, `btbox` bridges the gap between FreeBSD's stability and Linux's advanced Bluetooth hardware support and codec ecosystem.

Inspired by **[wifibox](https://github.com/pgj/freebsd-wifibox)**, `btbox` applies the same "Linux-in-a-VM-for-drivers" architecture to the Bluetooth audio and device management problem space.

**Creator:** orpheus497
**Status:** Version 0.1.0-alpha (INTERNAL DEVELOPMENT / UNRELEASED)

---

## 1. THE PURPOSE

FreeBSD's native Bluetooth stack (`ng_btx`) is robust but lacks support for modern high-definition audio codecs (LDAC, AptX HD, AAC) and modern Hands-Free Profile (HFP) implementations required by today's consumer headsets. 

`btbox` solves this by:
1.  **Hardware Passthrough**: Passing a dedicated USB Bluetooth controller (or PCI card) directly to a minimal Alpine Linux VM via Bhyve PCI passthrough.
2.  **Modern Stack**: Utilizing **BlueZ** (the Linux Bluetooth stack) and **PipeWire** (the modern Linux audio server) within the guest to handle complex protocol negotiations.
3.  **Audio + Microphone Bridging**: Streaming high-quality audio (A2DP, LDAC, AptX, AAC, SBC-XQ) and microphone input (HFP/HSP with mSBC) back to the FreeBSD host over TCP using the PulseAudio protocol.
4.  **Bluetooth Device Management**: Providing CLI commands to scan, pair, connect, trust, and remove Bluetooth devices — all from the FreeBSD host.

The result is a seamless experience where FreeBSD gets full Bluetooth audio output, microphone input, and device management powered by Linux's mature Bluetooth stack.

---

## 2. INSPIRATION & CREDITS

### Inspiration
*   **[wifibox](https://github.com/pgj/freebsd-wifibox)**: Created by **Pál Gyula Jensen (pgj)**. `btbox` is architecturally inspired by `wifibox`, applying the same "Linux-in-a-VM-for-drivers" philosophy specifically to the Bluetooth audio problem space.

### Technical Credits & Dependencies
*   **[FreeBSD Bhyve Team](https://www.freebsd.org/)**: For the lightweight hypervisor that makes this low-latency bridging possible.
*   **[Alpine Linux](https://alpinelinux.org/)**: For providing the incredibly small and efficient base for our guest image.
*   **[BlueZ](http://www.bluez.org/)**: The definitive Linux Bluetooth stack.
*   **[PipeWire](https://pipewire.org/) / [WirePlumber](https://pipewire.pages.freedesktop.org/wireplumber/)**: For the cutting-edge audio routing and session management.
*   **[grub-bhyve](https://github.com/grehan-freebsd/grub2-bhyve)**: For enabling the direct boot of the Linux kernel.

---

## 3. ARCHITECTURE OVERVIEW

*   **Host OS**: FreeBSD (13.0+, 14.0+ recommended).
*   **Hypervisor**: Bhyve (with `vmm.ko`).
*   **Guest OS**: Alpine Linux (Standard Virt Kernel).
*   **Bluetooth**: BlueZ + PipeWire + WirePlumber in the guest.
*   **Audio Transport**: PulseAudio protocol over TCP (port 4713) via virtual `tap` network.
*   **Hardware Control**: `ppt` (PCI passthrough) for USB Bluetooth controllers.
*   **Device Management**: SSH from host to guest, exposing `bluetoothctl` commands.

---

## 4. INSTALLATION & SETUP (ALPHA PREVIEW)

> [!WARNING]
> This software is currently in **0.1.0-alpha**. It is not yet ready for general use. The following instructions are for developers only.

### Prerequisites
*   FreeBSD 13.0-RELEASE or higher (14.0+ recommended).
*   CPU with VT-x/AMD-V and IOMMU (VT-d/AMD-Vi) support.
*   A spare USB controller for passthrough (integrated or PCI-e).

### Hardware Verification
Run the included verification script:
```bash
sh src/check_hw.sh
```

### Configuration
1.  Copy the sample config: `cp conf/btbox.conf.sample /usr/local/etc/btbox.conf`
2.  Identify your Bluetooth USB controller using `pciconf -lv`.
3.  Add the PCI ID to your `/boot/loader.conf` for `ppt` passthrough.

### SSH Key Setup (required for device management)
The `btbox scan/pair/connect` commands execute `bluetoothctl` inside the guest VM over SSH.
You must add your host's public SSH key to the guest image overlay before building it:
```bash
# Copy your public key into the overlay
cat ~/.ssh/id_ed25519.pub >> guest/overlay/etc/btbox/host_authorized_keys

# Rebuild the guest image
sh guest/build_alpine.sh
```

### Usage
```bash
# Start the btbox VM
btbox start

# Scan for nearby Bluetooth devices
btbox scan

# Pair, trust, and connect a device
btbox pair AA:BB:CC:DD:EE:FF
btbox trust AA:BB:CC:DD:EE:FF
btbox connect AA:BB:CC:DD:EE:FF

# List connected devices
btbox devices

# Disconnect or remove a device
btbox disconnect AA:BB:CC:DD:EE:FF
btbox remove AA:BB:CC:DD:EE:FF

# Check VM status
btbox status

# Stop the VM
btbox stop
```

### Connecting Audio on the Host
Once a Bluetooth device is connected, configure PulseAudio on the FreeBSD host to use the btbox audio bridge:
```bash
# Set the PulseAudio server to the btbox guest
export PULSE_SERVER=tcp:10.0.0.2:4713
```

---

## 5. LICENSE

`btbox` is released under the **BSD 2-Clause License**. See the `LICENSE` file for details.
