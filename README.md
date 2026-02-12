# btbox (Bluetooth Box for FreeBSD)

**btbox** is a specialized virtualization wrapper designed to bring modern, high-fidelity Bluetooth Audio support to FreeBSD. By leveraging a lightweight Alpine Linux guest running under the Bhyve hypervisor, `btbox` bridges the gap between FreeBSD's stability and Linux's advanced Bluetooth hardware support and codec ecosystem.

**Creator:** orpheus497 (@cyronetics)  
**Status:** Version 0.1.0-alpha (INTERNAL DEVELOPMENT / UNRELEASED)

---

## 1. THE PURPOSE

FreeBSD's native Bluetooth stack (`ng_btx`) is robust but lacks support for modern high-definition audio codecs (LDAC, AptX HD, AAC) and modern Hands-Free Profile (HFP) implementations required by today's consumer headsets. 

`btbox` solves this by:
1.  **Hardware Passthrough**: Passing a dedicated USB Bluetooth controller (or PCI card) directly to a minimal Alpine Linux VM.
2.  **Modern Stack**: Utilizing **BlueZ** (the Linux Bluetooth stack) and **PipeWire** (the modern Linux audio server) within the guest to handle complex protocol negotiations.
3.  **Audio Bridging**: Streaming high-quality audio back to the FreeBSD host over a virtualized network interface using the PulseAudio protocol over TCP.

The result is a seamless experience where FreeBSD "sees" a PulseAudio-compatible output device that, in reality, is a high-performance Linux-driven Bluetooth bridge.

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

*   **Hypervisor**: Bhyve (with `vmm.ko`).
*   **Guest OS**: Alpine Linux (Standard Virt Kernel).
*   **Network**: Virtual `tap` device bridged to a `bridge` or local network for TCP audio transport.
*   **Hardware Control**: `ppt` (PCI passthrough) for USB controllers.

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

---

## 5. LICENSE

`btbox` is released under the **BSD 2-Clause License**. See the `LICENSE` file for details.