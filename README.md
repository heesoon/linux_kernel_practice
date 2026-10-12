# 🐧 Linux Kernel & QEMU Workspace

[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://kernel.org)
[![BusyBox](https://img.shields.io/badge/BusyBox-555555?style=for-the-badge)](https://busybox.net)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
[![QEMU](https://img.shields.io/badge/QEMU-FF6600?style=for-the-badge&logo=qemu&logoColor=white)](https://qemu.org)

> A minimal automated workspace designed to fetch Linux Kernel & BusyBox source code, build custom images via host or Docker container, and emulate the environment instantly using QEMU.

---

## 📂 Project Architecture

```text
linux_workspace/
├── build.sh             # Host-level kernel and rootfs compilation script
├── container_build.sh   # Containerized build environment script (Docker)
├── dockerfile           # Docker isolation environment configuration
├── qemu_run.sh          # QEMU emulation launcher with custom args
├── out/                 # Compiled kernel bzImage and final artifacts target
├── rootfs/              # Skeleton directory for the initial root filesystem
└── src/                 # Main upstream source trees
    ├── busybox-1.38.0/  # Vanilla BusyBox source directory
    └── linux-7.2.6/     # Mainline Linux kernel repository
```

---

## 🚀 Usage

호스트 OS 환경의 오염을 방지하기 위해 모든 빌드 패키지 도구 체인은 `container_build.sh` 내부 도커 환경에 격리되어 처리됩니다. 다음 흐름에 맞춰 컴파일 및 에뮬레이션을 수행하세요.

### Step 1: Build the Kernel & Rootfs
원하는 환경에 맞춰 아래 스크립트 중 하나를 선택해 소스를 컴파일합니다.
```bash
# 로컬 호스트 환경에서 직접 빌드 시
./build.sh

# 도커 컨테이너 격리 환경에서 빌드 시
./container_build.sh
```

### Step 2: Emulate via QEMU
컴파일이 완료되면 `out/` 폴더에 생성된 산출물을 기반으로 가상 머신 가동을 시작합니다.
```bash
./qemu_run.sh
```
