# 🐧 Linux Kernel & QEMU Workspace

[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://kernel.org)
[![BusyBox](https://img.shields.io/badge/BusyBox-555555?style=for-the-badge)](https://busybox.net)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
[![QEMU](https://img.shields.io/badge/QEMU-FF6600?style=for-the-badge&logo=qemu&logoColor=white)](https://qemu.org)

**macOS에서 Docker로 ARM64 Linux 커널과 BusyBox 기반 initramfs를 빌드하고, 호스트의 QEMU로 부팅하는 최소 개발 워크스페이스입니다.**

커널 컴파일러와 빌드 의존성을 Ubuntu 컨테이너에 모아 호스트에 Linux 빌드 도구를 직접 설치하는 부담을 줄입니다. Git에는 빌드 환경과 실행 스크립트를 관리하고, 소스와 빌드 결과물은 로컬에서 준비·생성합니다. 커널 부팅 과정, initramfs 구성, BusyBox 사용자 공간을 실험하는 용도로 사용할 수 있습니다.

> 현재 구현은 Apple Silicon Mac의 ARM64 빌드 흐름을 기준으로 합니다. 소스 다운로드와 QEMU 실행은 빌드 스크립트에 포함되어 있지 않으며, 각각 준비 단계와 별도 실행 단계로 진행합니다.

## 구성과 실행 흐름

```text
호스트: macOS / Docker + QEMU
  │
  ├─ bash build.sh
  │    └─ Ubuntu 22.04 ARM64 컨테이너
  │         └─ bash container_build.sh
  │              ├─ BusyBox 정적 빌드 → rootfs/
  │              ├─ /init 생성 → out/initramfs.cpio.gz
  │              └─ Linux ARM64 빌드 → out/Image
  │
  └─ bash qemu_run.sh
       └─ QEMU ARM64 virt 머신 → /init → BusyBox init → rcS → 콘솔 셸
```

| 구성 요소 | 현재 설정 |
| --- | --- |
| 빌드 환경 | `ubuntu:22.04`, `linux/arm64` |
| Linux 소스 디렉터리 | `src/linux-7.2.6/` |
| BusyBox 소스 디렉터리 | `src/busybox-1.38.0/` |
| 커널 설정 / 타깃 | `make defconfig` / `make Image` |
| 사용자 공간 | 정적 링크한 BusyBox |
| 루트 파일시스템 | gzip 압축한 `newc` 형식의 initramfs |
| 가상 머신 | `qemu-system-aarch64`, `virt`, `cortex-a57` |
| 게스트 메모리 / 콘솔 | 1 GiB / `ttyAMA0` |

## 디렉터리 구조

```text
linux_workspace/
├── README.md
├── .gitignore
├── build.sh                  # 호스트에서 Docker 빌드와 컨테이너 실행을 관리
├── container_build.sh        # 컨테이너 내부에서 BusyBox·initramfs·커널 빌드
├── dockerfile                # Ubuntu ARM64 빌드 환경
├── qemu_run.sh               # 호스트에서 QEMU 실행
├── src/                      # 별도로 준비하는 소스; Git 제외
│   ├── busybox-1.38.0/
│   └── linux-7.2.6/
├── rootfs-overlay/           # Git으로 관리하는 /init, inittab, rcS
├── rootfs/                   # 빌드 때 다시 생성되는 루트 파일시스템; Git 제외
└── out/                      # 최종 산출물; Git 제외
    ├── Image
    └── initramfs.cpio.gz
```

`Image`는 ARM64 커널 이미지입니다. 이 프로젝트는 x86의 `bzImage`나 영구 저장용 디스크 이미지를 생성하지 않습니다.

## 사전 준비

- Docker를 설치하고 Docker 엔진을 실행합니다. macOS에서는 Docker Desktop 등의 Linux 컨테이너 실행 환경이 필요합니다.
- 호스트에 `qemu-system-aarch64`를 설치합니다. Homebrew를 사용하는 macOS 환경에서는 `brew install qemu`로 설치할 수 있습니다.
- 소스 준비에 필요한 Git, `curl`, `tar`를 사용할 수 있어야 합니다.
- 첫 빌드에는 Ubuntu 이미지와 패키지 다운로드를 위한 인터넷 연결이 필요합니다. 소스 다운로드에도 네트워크가 필요합니다.
- Docker에 커널 컴파일을 수행할 CPU·메모리·디스크 여유를 할당합니다. 병렬 빌드 수는 컨테이너의 `nproc` 값으로 결정됩니다.

```bash
docker info
qemu-system-aarch64 --version
```

모든 명령은 **저장소 최상위 디렉터리**에서 실행합니다. `build.sh`는 현재 작업 디렉터리를 컨테이너에 마운트하므로 다른 위치에서 실행하면 소스와 스크립트를 찾지 못할 수 있습니다.

## 빠른 시작

### 1. 저장소 복제

```bash
# <repository-url>을 실제 저장소 주소로 바꿉니다.
git clone <repository-url> linux_workspace
cd linux_workspace
```

### 2. 소스 준비

`src/`는 Git에서 제외되어 있으므로 처음 복제한 저장소에는 소스가 없습니다. 다음 명령으로 스크립트가 기대하는 버전과 디렉터리를 준비합니다. 이미 소스가 있다면 이 단계는 생략합니다.

```bash
mkdir -p src
curl -fL https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.2.6.tar.xz \
  -o src/linux-7.2.6.tar.xz
curl -fL https://busybox.net/downloads/busybox-1.38.0.tar.bz2 \
  -o src/busybox-1.38.0.tar.bz2

tar -xf src/linux-7.2.6.tar.xz -C src
tar -xf src/busybox-1.38.0.tar.bz2 -C src
```

원본 압축 파일을 별도로 보관한 경우에도 `src/`에 압축을 해제하면 됩니다. 다른 버전을 사용하려면 디렉터리 이름만 바꾸지 말고 `container_build.sh`의 소스 경로와 관련 표기도 함께 수정합니다.

### 3. 초기화 구성 확인

`rootfs-overlay/`의 파일은 빌드할 때 rootfs로 복사됩니다.

- `/init`: `/dev`를 마운트하고 `exec /sbin/init`으로 BusyBox init을 PID 1로 실행합니다.
- `/etc/inittab`: `sysinit`으로 `rcS`를 한 번 실행한 뒤 `ttyAMA0`에서 콘솔 셸을 시작합니다.
- `/etc/init.d/rcS`: `/proc`, `/sys`, 임시 디렉터리를 준비하고 배너를 출력합니다.

`ttyAMA0::respawn:/bin/sh` 설정에 따라 셸에서 `exit`하면 init은 살아 있는 상태로 새 셸을 실행합니다. 인증 없는 개발용 콘솔입니다. systemd는 사용하지 않습니다.

### 4. 커널과 initramfs 빌드

```bash
bash build.sh
# 또는: macOS에서는 같은 Docker 빌드로 자동 연결됩니다.
bash container_build.sh
```

`build.sh`는 다음 작업을 순서대로 수행합니다.

1. `linux-builder-env` Docker 이미지를 생성하거나 갱신합니다.
2. 이름이 `linux-builder-run`인 기존 컨테이너를 제거합니다.
3. 프로젝트 디렉터리를 `/home/developer`에 마운트하고 `container_build.sh`를 실행합니다.
4. 성공하면 실행 컨테이너를 제거하고 `docker image prune -f`로 dangling 이미지를 정리합니다.

컨테이너 내부에서는 BusyBox를 정적으로 빌드·설치하고, `/init`을 생성한 뒤 initramfs를 압축합니다. 이어서 Linux 커널을 빌드하여 `out/Image`로 복사합니다.

```bash
ls -lh out/Image out/initramfs.cpio.gz
```

### 5. QEMU 부팅

```bash
bash qemu_run.sh
```

빌드부터 부팅까지 연속 실행하려면 다음 명령을 사용합니다. 빌드 성공 시에만 QEMU가 시작됩니다.

```bash
bash build.sh && bash qemu_run.sh
```

게스트 부팅이 완료되면 다음 배너와 셸이 나타납니다.

```text
==========================================
    WELCOME TO MY BUSYBOX 1.38.0 LINUX
==========================================
```

게스트에서 다음 명령으로 커널과 마운트 상태를 확인할 수 있습니다.

```sh
uname -a
cat /proc/version
mount
ls /bin
```

**QEMU 종료:** `Ctrl+A`를 누른 뒤 키를 놓고 `X`를 누릅니다. 셸에서 `exit`하면 BusyBox init이 새 셸을 실행합니다. 게스트 종료에는 `poweroff`를 사용합니다.

## 부팅 이미지와 QEMU 설정

`rootfs/init`은 `/dev`를 준비하고 BusyBox init을 실행합니다. init은 `/etc/inittab`에 따라 `rcS` 실행과 콘솔 셸 재시작, 종료 작업을 관리합니다.

`qemu_run.sh`의 실행 명령은 다음과 같습니다.

```bash
qemu-system-aarch64 -M virt -cpu cortex-a57 -m 1024M \
  -kernel out/Image \
  -initrd out/initramfs.cpio.gz \
  -nographic -append "rdinit=/init console=ttyAMA0"
```

| 옵션 | 역할 |
| --- | --- |
| `-M virt` | ARM 가상 머신 플랫폼 선택 |
| `-cpu cortex-a57` | 게스트 CPU 모델 선택 |
| `-m 1024M` | 게스트 메모리 설정 |
| `-kernel` / `-initrd` | 커널과 initramfs 지정 |
| `-nographic` | 터미널에서 콘솔 사용 |
| `rdinit=/init` | initramfs의 첫 실행 프로그램 지정 |
| `console=ttyAMA0` | PL011 시리얼 콘솔로 부팅 로그 출력 |

메모리와 CPU 모델, 커널 인자는 `qemu_run.sh`에서 변경합니다. 현재 스크립트는 전달받은 명령행 인자를 추가하지 않으므로 `bash qemu_run.sh -m 2048M`처럼 옵션을 덧붙여도 적용되지 않습니다. 가속기와 영구 디스크, 네트워크 포워딩 설정도 별도로 지정하지 않습니다.

## 다른 환경에서 재사용하기

Git으로 관리하는 항목은 README, 빌드 스크립트, Docker 설정, `rootfs-overlay/`, `.gitignore`입니다. `src/`, `rootfs/`, `out/`는 복제 후 다시 준비하거나 생성합니다.

- **Apple Silicon macOS:** ARM64 컨테이너에서 빌드하고 호스트 QEMU로 실행하는 기본 구성입니다.
- **ARM64 Linux:** Docker와 호스트 QEMU가 필요합니다. bind mount 디렉터리에 컨테이너 사용자가 쓸 수 있는지 확인합니다.
- **Intel Mac / x86_64 Linux:** ARM64 컨테이너 실행을 위한 에뮬레이션 지원이 필요합니다. 이 구성에서는 ARM64 컨테이너 안에서 빌드하며, x86 커널로 자동 전환하지 않습니다. 빌드 속도와 실행 가능 여부는 Docker 환경에 따라 달라집니다.

Docker는 `developer` 사용자로 빌드하지만 호스트 UID/GID를 자동으로 맞추지는 않습니다. Linux에서 권한 오류가 발생하면 사용자 ID와 마운트 디렉터리 소유권을 조정해야 합니다.

이 저장소는 빌드 절차를 재사용하기 위한 구성입니다. Ubuntu 이미지 digest, APT 패키지 버전, 소스 체크섬, 최종 `.config`는 고정·관리하지 않으므로 바이트 단위로 동일한 결과를 보장하지 않습니다. 재현성을 강화하려면 해당 정보를 별도로 기록하고 고정합니다.

## 수정과 재빌드

- **커널 설정:** `container_build.sh`의 `make defconfig` 이후에 설정 변경 단계를 추가합니다. 현재는 매번 기본 설정을 생성하므로 소스 디렉터리의 `.config`만 수동으로 수정하면 다음 빌드에서 덮어써집니다.
- **BusyBox 설정:** BusyBox도 매번 `make defconfig`를 실행하며 `CONFIG_STATIC=y`를 적용합니다. 추가 설정은 그 이후에 반영합니다.
- **초기화 동작:** `rootfs-overlay/init`, `rootfs-overlay/etc/inittab`, `rootfs-overlay/etc/init.d/rcS`를 수정하고 다시 빌드합니다.
- **루트 파일 추가:** initramfs 패키징 전에 파일을 복사하는 단계를 추가합니다. `rootfs/`는 빌드 시작 시 삭제·재생성되므로 수동으로 넣은 파일은 다음 빌드에서 사라집니다.

소스 트리의 기존 빌드 결과는 유지되지만 빌드 설정과 rootfs는 다시 생성됩니다. 독립적인 여러 작업을 동시에 실행하면 고정된 컨테이너 이름이 충돌하므로 이름을 분리해야 합니다.

## 문제 해결

| 증상 | 확인 및 조치 |
| --- | --- |
| Docker 데몬 연결 오류 | Docker 엔진을 시작하고 `docker info` 확인 |
| Dockerfile을 찾지 못함 | 저장소 최상위에서 실행하고 `build.sh`에 `-f dockerfile` 명시 |
| `src/linux-7.2.6`을 찾지 못함 | 소스 다운로드·압축 해제 및 디렉터리 이름 확인 |
| BusyBox가 없는데 initramfs가 생성됨 | 현재 빌드는 BusyBox 소스가 없으면 즉시 중단. 소스 디렉터리를 준비하고 다시 실행 |
| `Permission denied` | 컨테이너 `developer` 사용자와 bind mount 디렉터리 권한 확인 |
| 컴파일 중 프로세스 종료 / 메모리 부족 | Docker 메모리 할당을 늘리거나 스크립트의 `make -j` 병렬 수 축소 |
| `qemu-system-aarch64: command not found` | 호스트에 QEMU 설치 후 PATH 확인 |
| `/init` 실행 실패 또는 커널 패닉 | BusyBox 정적 빌드 성공 여부, ARM64 아키텍처, `/init` 실행 권한, initramfs 구성 확인 |
| 빌드 실패 후 컨테이너가 남음 | `docker logs linux-builder-run`으로 로그 확인 후 `docker rm -f linux-builder-run` 실행 |

`set -e`로 인해 빌드 실패 시 성공 후 정리 단계까지 진행하지 않을 수 있습니다. 실패한 빌드 뒤에는 기존 `out/` 파일이 남거나 새 initramfs와 이전 커널이 함께 존재할 수 있으므로, 산출물 존재 여부만으로 성공을 판단하지 않습니다.

`build.sh`의 `docker image prune -f`는 프로젝트에 한정되지 않은 dangling 이미지 정리입니다. 빌드 환경 이미지 `linux-builder-env` 자체를 삭제하는 명령은 아닙니다.

## 참고 문서

- [Linux Kernel Archives](https://kernel.org)
- [BusyBox 다운로드](https://busybox.net/downloads/)
- [Dockerfile 파일 이름과 빌드 설정](https://docs.docker.com/build/concepts/dockerfile/)
- [QEMU 문서](https://www.qemu.org/docs/master/)

Linux와 BusyBox 소스의 이용·수정·배포 조건은 각 소스 트리의 라이선스 파일을 확인합니다. 이 워크스페이스의 스크립트에 적용할 라이선스는 저장소에서 별도로 명시해야 합니다.
