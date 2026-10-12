### 1. 최상위 디렉토리 및 파일 구성 (`linux_workspace`)

```text
.
├── build.sh             # [실행] 로컬 커널/소스 빌드 스크립트
├── container_build.sh   # [실행] 도커 컨테이너 기반 빌드 스크립트
├── dockerfile           # 컨테이너 빌드 환경 정의 파일
├── qemu_run.sh          # [실행] 빌드된 이미지를 QEMU로 구동하는 스크립트
├── src/                 # 리눅스 커널 또는 애플리케이션 소스 코드 디렉토리
├── rootfs/              # 초기 파일 시스템(Root Filesystem) 구성 폴더
└── out/                 # 빌드 결과물(커널 이미지, 이미지 파일 등) 저장 폴더
```

### 2. `src` 디렉토리 구성

```text
./src
├── busybox-1.38.0/      # BusyBox 소스 코드 및 빌드 디렉토리
└── linux-7.2.6/         # 리눅스 커널 소스 트리 디렉토리
```
