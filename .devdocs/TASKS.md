# CENTRAL TASK BOARD

This is the single source of truth for work assignments. All Agents must check this list before starting work.

**Status Legend:**
*   `[ ]` To Do
*   `[/]` In Progress
*   `[x]` Done

**Priority Legend:**
*   (P0) Critical / Blocker
*   (P1) High / Core Feature
*   (P2) Medium / Polish
*   (P3) Low / Future

---

## 🚀 Active Sprint: Initialization & MVP

### 🏗️ Agent A1: The Architect
- [x] (P0) Initialize Project Structure & `.devdocs` ecosystem.
- [x] (P0) Define Architecture (Bhyve + Alpine + Passthrough).
- [x] (P0) Create Configuration Template (`btbox.conf`).

### ⚙️ Agent A2: The Logic Engineer
- [ ] (P0) **Guest OS Builder**: Create `guest/build_alpine.sh` to download and construct the Alpine rootfs.
- [ ] (P0) **Guest Config**: Create overlay files for Guest (BlueZ config, PipeWire config, Init scripts).
- [ ] (P0) **Host Logic**: Develop `src/btbox` main executable script (config parsing, validation).
- [ ] (P0) **Hypervisor Control**: Implement `src/vmm/bhyve_runner.sh` (or function) to handle the `bhyve` command execution with PCI passthrough.
- [ ] (P1) **Network Bridge**: Implement tap/bridge creation logic in Host script.

### 🎨 Agent A3: The Interface Designer
- [x] (P2) **CLI UX**: Ensure `btbox` command outputs are colored, clear, and follow FreeBSD rc.d style.
- [x] (P3) **Logo/Banner**: Create an ASCII banner for the CLI startup.

### 🛡️ Agent A6: The Sentinel
- [ ] (P1) **Permission Check**: Audit `src/btbox` to ensure it handles root privileges correctly (required for bhyve).
- [ ] (P1) **Network Security**: Verify `iptables` rules in Guest and Host (if used) don't expose open ports unnecessarily.

### ⚖️ Agent A7: The Marshal
- [ ] (P2) **Linting**: Setup `shellcheck` for all shell scripts.

### 🧪 Agent A4: The Test Engineer
- [ ] (P1) **Mock Testing**: Create a mock test for config parsing (verify it catches missing variables).
- [ ] (P2) **Hardware Check**: Create a utility to verify if the user's system supports VT-d (IOMMU) before running.

---

## 🧊 Backlog (Future Features)
- [ ] (P3) Support for suspending/resuming the VM.
- [ ] (P3) Auto-detection of USB Bluetooth controllers.
- [ ] (P3) "Headless" mode integration with FreeBSD `rc.d` service.
