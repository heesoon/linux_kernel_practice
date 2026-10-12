# 🚀 Linux Kernel & QEMU Workspace

<p align="left">
  <img src="https://shields.io" alt="Linux">
  <img src="https://shields.io" alt="Docker">
  <img src="https://shields.io" alt="QEMU">
</p>

> Git에서 리눅스 커널과 BusyBox 소스코드를 받아 로컬 또는 도커 컨테이너 환경에서 빌드하고, QEMU 가상 머신으로 가볍고 빠르게 부팅하는 자동화 작업 공간입니다.

---

## 📂 프로젝트 디렉토리 구조 (Directory Structure)

### 📌 1. 최상위 디렉토리 및 파일 구성
```text
linux_workspace/
├── ⚙️ build.sh              # [실행] 로컬 커널 및 소스 빌드 스크립트
├── 🐳 container_build.sh    # [실행] 도커 컨테이너 기반 빌드 스크립트
├── 📄 dockerfile            # 컨테이너 빌드 환경 정의 파일
├── 🖥️ qemu_run.sh           # [실행] 빌드된 이미지를 QEMU로 구동하는 스크립트
├── 📦 src/                  # 리눅스 커널 및 소스 코드 저장 디렉토리
├── 📁 rootfs/               # 초기 파일 시스템(Root Filesystem) 구성 폴더
└── 📤 out/                  # 빌드 결과물(커널 이미지 등) 저장 폴더
```

### 📁 2. `src/` 하위 디렉토리 상세
```text
./src/
├── 📦 busybox-1.38.0/       # BusyBox 소스 코드 및 빌드 공간
└── 🐧 linux-7.2.6/          # 리눅스 커널 메인 소스 트리
```

---

## 🚀 시작하기 (Quick Start)

### 🛠️ 빌드하기
원하는 환경에 맞춰 아래 스크립트 중 하나를 실행합니다.
```bash
# 로컬 빌드 환경 이용 시
./build.sh

# 도커 컨테이너 환경 이용 시
./container_build.sh
```

### 🖥️ QEMU 실행하기
컴파일이 완료되면 `out/` 폴더에 생성된 이미지를 기반으로 가상 머신을 띄웁니다.
```bash
./qemu_run.sh
```
