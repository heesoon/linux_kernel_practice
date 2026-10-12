# 🐧 Linux Kernel & QEMU Workspace

<p align="left">
  <img src="https://shields.io" alt="Linux">
  <img src="https://shields.io" alt="Docker">
  <img src="https://shields.io" alt="QEMU">
</p>

> A minimal automated workspace designed to fetch Linux Kernel & BusyBox source code, build custom images via host or Docker container, and emulate the environment instantly using QEMU.

---

## 📂 Project Architecture

```text
linux_workspace/
├── build.sh             # Host-level kernel and rootfs compilation script
├── container_build.sh   # Containerized build environment script
├── dockerfile           # Docker isolation environment configuration
├── qemu_run.sh          # QEMU emulation launcher with custom args
├── out/                 # Compiled kernel bzImage and final artifacts target
├── rootfs/              # Skeleton directory for the initial root filesystem
└── src/                 # Main upstream source trees
    ├── busybox-1.38.0/  # Vanilla BusyBox source directory
    └── linux-7.2.6/     # Mainline Linux kernel repository
```

---

## 🚀 Getting Started

### Prerequisites
Ensure your host machine has the required toolchains installed:
```bash
sudo apt-get update && sudo apt-get install -y qemu-system-x86 build-essential
```

### Usage
Run the compilation flow and bootstrap the kernel inside QEMU:

```bash
# Step 1: Build the kernel and rootfs (Choose one)
./build.sh            # Local host build
./container_build.sh  # Docker container build

# Step 2: Emulate via QEMU
./qemu_run.sh
```
