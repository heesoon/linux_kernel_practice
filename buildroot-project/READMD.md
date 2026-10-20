# 🛠️ Advanced Embedded Linux System (Buildroot + systemd)

이 프로젝트는 **Buildroot**를 활용하여 M1 Mac(Apple Silicon) 및 Docker 환경에서 고도화된 ARM64 임베디드 리눅스를 구축하는 고급 워크스페이스입니다. 
단순히 셸만 뜨는 BusyBox 단계를 넘어, 최신 리눅스의 표준 표준 이닛 시스템인 `systemd`와 강력한 네트워크 인프라, 그리고 **Python, Rust, Flutter 응용 프로그램**을 구동할 수 있는 최적화된 맞춤형 OS 인프라 생성을 목표로 합니다.

---

## 🎯 주요 기능 및 아키텍처 목표

1. **Modern Init System**: `systemd` 기반의 체계적인 서비스 및 데몬 관리
2. **Robust Network**: `systemd-networkd` 및 `Dropbear SSH` 원격 제어 환경 자동화
3. **Advanced Runtime Subsystems**:
   * **Python 3**: 범용 스크립트 가동 및 제어를 위한 인터프리터 탑재
   * **Rust**: 고성능·안정성을 확보한 컴파일드 바이너리 실행 인프라 구축
   * **Flutter Embedded**: 디스플레이 출력이 없는 임베디드 보드에서도 커스텀 그래픽 임베더(예: `flutter-pi` 등 드라이버 연동)를 활용한 UI/UX 구현

---

## 📂 디렉터리 구조

`buildroot-project/` 디렉터리 내부는 다음과 같이 완전 격리된 구조로 운영됩니다.

```text
buildroot-project/
├── README.md                # 현재 안내 파일
├── build.sh                 # 호스트(Mac) 전용 Docker 버퍼 빌드 컨트롤러
├── container_build.sh       # 컨테이너 내 Buildroot 파이프라인 자동화 스크립트
├── dockerfile               # rsync, python3 등 Buildroot 전용 우분투 환경
├── qemu_run.sh              # 포트 포워딩(2222) 및 ext4 마운트 가상머신 구동 스크립트
└── configs/
    └── buildroot_defconfig # 빌드 가속화 및 아키텍처 설정을 박제한 고유 설정 파일
```

---

## 🛠️ Buildroot 핵심 핵심 설정 (menuconfig 가이드)

프로젝트 최초 빌드 시 `make menuconfig`에 진입하여 아래 핵심 서브시스템 목록을 반드시 활성화해야 합니다.

### 1. 기본 인프라 및 systemd (필수)
* `Target options` -> Target Architecture: `AArch64 (little endian)`
* `Toolchain` -> `Enable WCHAR support` & `Enable threads` **(systemd 필수 조건, 체크)**
* `System configuration` -> Init system: **`systemd` 변경**
* `Target packages` -> `Networking applications` -> **`dropbear` (SSH 활성화)**

### 2. 고급 언어 및 그래픽 런타임 활성화 (목표)
* **Python 3**: `Target packages` -> `Interpreter languages and scripting` -> `python3` 체크
* **Rust**: `Target packages` -> `Development tools` -> `rustc` 및 필요시 `cargo` 컴파일러 탑재
* **Flutter Graphic Subsystem**: 
  * `Target packages` -> `Graphic libraries and applications` 내 인터페이스 환경 설정 
  * (필요 시 DRM/KMS 기반 사양 및 OpenGL ES 드라이버 종속성 가동)

---

## 🚀 실행 프로세스

### 1. 통합 빌드 (Docker 컨테이너 캐시 볼륨 활용)
```bash
# macOS 호스트 실행
bash build.sh
```
* 컨테이너 내부의 독립 가속 볼륨(`/build_fast`)에서 교차 컴파일을 진행하며, 완료 시 호스트의 `./out/` 디렉터리로 `Image`(커널)와 `rootfs.ext4`(루트 이미지)를 추출합니다.

### 2. QEMU 가상머신 가동 및 SSH 접속
```bash
# macOS 호스트 실행
bash qemu_run.sh
```
* 내부 `systemd-networkd`가 동작하며 포트 포워딩 인터페이스를 엽니다.
* 맥북 호스트 터미널을 새로 열어 원격으로 SSH 접속을 진행합니다:
  ```bash
  ssh root@localhost -p 2222
  ```

---

## 📈 응용 프로그램 탑재 및 실습 시나리오

1. **systemd 커스텀 서비스 등록**: `/etc/systemd/system/`에 `.service` 파일을 박아 부팅 시 직접 짠 앱이 자동 구동되도록 설계합니다.
2. **Python/Rust 애플리케이션 이식**: 호스트에서 ARM64로 교차 컴파일하거나 스크립트를 루트 파일시스템 안에 마운트시켜 구동 성능을 검증합니다.
3. **Flutter 가동**: 가상 머신 혹은 타겟 보드의 그래픽 백엔드에 맞춰 경량 임베더 위에 Flutter 빌드 산출물(`flutter_assets`)을 올리고 GUI 스크린을 출력합니다.
