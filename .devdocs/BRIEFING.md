# PROJECT BRIEFING: btbox

**Objective:**
Replicate the functionality of `wifibox` but for Bluetooth Audio.
Enable high-quality Bluetooth audio (A2DP, HFP, mSBC/LC3) on FreeBSD by utilizing a lightweight Linux (Alpine) VM running BlueZ/PipeWire, bridging audio to the FreeBSD host.

**Current Phase:**
Development / Implementation

**Work Tracking:**
> **[VIEW CENTRAL TASK BOARD](TASKS.md)** <
> *All agents must pull tasks from TASKS.md*

**Active Agent:**
Transitioning from A1 (Architect) to A2 (Logic Engineer)

**Key Architecture:**
*   **Host:** FreeBSD (Audio Client)
*   **Hypervisor:** Bhyve
*   **Guest:** Alpine Linux (BlueZ + PipeWire Server)
*   **Bridge:** 
    *   Hardware: PCI Passthrough of USB Controller (for Bluetooth dongle/card).
    *   Audio: Network Audio (PipeWire/PulseAudio protocol via Virtual Ethernet).

**Status:**

*   [x] Project Initialization

*   [x] Skeleton Created

*   [x] Guest Image Build System

*   [x] Host Launch Scripts

*   [x] Security Hardening

*   [x] CLI UX/Branding

*   [x] CI/CD Pipeline

*   [ ] Integration Testing (Pending Hardware Access)



**Next Steps:**

Handover to Agent #10 (Gatekeeper) for formal release and version tagging.
