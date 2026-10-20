# 🐧 Linux Kernel & Advanced Workspace

이 저장소는 **macOS (Apple Silicon)** 환경에서 Docker와 QEMU를 활용해 ARM64 임베디드 리눅스 시스템을 빌드하고 부팅하는 단계별 실습 워크스페이스입니다. 미니멀한 BusyBox 환경에서 나아가 Buildroot 기반의 멀티 프로젝트 구조를 관리합니다.

---

## 📂 전체 디렉터리 구조

저장소 루트에서 모든 하위 프로젝트와 스크립트를 통합 관리합니다. 전체 구조의 상세 내용은 리포지토리의 파일 트리를 참고해 주시기 바랍니다.

*   `linux_kernel_practice/`
    *   `.gitignore`: 빌드 산출물 및 소스 공통 제외 규칙
    *   `README.md`: 프로젝트 안내 및 로드맵
    *   `busybox-project/`: BusyBox & initramfs 기반 워크스페이스 (`build.sh`, `container_build.sh`, `dockerfile`, `qemu_run.sh`, `rootfs-overlay/`)
    *   `buildroot-project/`: Buildroot & systemd 기반 고도화 워크스페이스 (`build.sh`, `container_build.sh`, `dockerfile`, `qemu_run.sh`, `configs/buildroot_defconfig`)

---

## 🗺️ 개발 로드맵 (Development Roadmap)

1.  **1단계: BusyBox 기반 최소 리눅스 시스템 (완료)**
    *   커널 부팅 메커니즘과 PID 1(`init`) 프로세스의 동작 원리 학습
2.  **2단계: Buildroot + systemd 고도화 시스템 (현재 진행 중)**
    *   `make menuconfig` 기반 크로스 컴파일, systemd 통합, Dropbear SSH 네트워크 인프라 구축
3.  **3단계: Yocto Project 기반 기업형 배포판 시스템 (예정)**
    *   메타레이어와 비트베이크 레시피 기반 고확장성 아키텍처 학습

---

## 🛠️ 핵심 실행 흐름 및 주의사항

*   **Git 관리 정책:** 하위 폴더에 중복 `.git`을 생성하지 않으며, 모든 Git 명령어는 최상위 루트에서 수행합니다.
*   **호스트 환경:** macOS `qemu-system-aarch64` 및 Docker Desktop 필요.
*   **컴파일 가속:** Buildroot는 Mac-Docker 간 파일 시스템 병목을 방지하기 위해 가상 도커 캐시 볼륨을 활용합니다.
