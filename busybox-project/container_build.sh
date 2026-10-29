#!/bin/bash
set -e

# ==============================================================================
# [0] 환경 변수 및 가속 경로 정의
# ==============================================================================
HOST_WORKSPACE="/home/developer"
FAST_VOLUME="/build_fast"

SRC_DIR="$HOST_WORKSPACE/src"
OVERLAY_BIN_DIR="$HOST_WORKSPACE/rootfs-overlay/bin"

BUSYBOX_DIR="$FAST_VOLUME/src/busybox-1.38.0"
KERNEL_DIR="$FAST_VOLUME/src/linux-7.3"
APP_BUILD_DIR="$FAST_VOLUME/app_build"
ROOTFS_DIR="$FAST_VOLUME/rootfs"
OUT_DIR="$FAST_VOLUME/out"

echo "👉 [도커 내부] 가속 볼륨 작업 공간을 준비합니다."
cd $FAST_VOLUME
mkdir -p src out

# ==============================================================================
# [1] 사용자 C++ 프로그램 빌드 및 이식 (CMake 멀티 빌드 반영)
# ==============================================================================
echo "🛠️ [1/5] CMake를 이용해 사용자 어플리케이션 일괄 빌드 시작..."

# 소스 디렉터리 및 마스터 CMakeLists.txt 존재 여부 검증
if [ ! -f "$SRC_DIR/CMakeLists.txt" ]; then
    echo "❌ [에러] $SRC_DIR/CMakeLists.txt 파일이 존재하지 않습니다."
    echo "    - 멀티 앱 구조 설정을 먼저 완료해 주세요."
    exit 1
fi

# 도커 가속 공간에서 빌드 수행
rm -rf "$APP_BUILD_DIR"
mkdir -p "$APP_BUILD_DIR"
cd "$APP_BUILD_DIR"

echo "🔄 [도커 내부] $SRC_DIR 전체 소스를 기반으로 CMake 구성 중..."
cmake "$SRC_DIR"
make -j$(nproc)

# 호스트 오버레이 폴더 내 bin 디렉터리 초기화 및 결과물 복사
mkdir -p "$OVERLAY_BIN_DIR"
rm -f "$OVERLAY_BIN_DIR"/*

echo "🚚 [도커 내부] 빌드 완료된 바이너리를 rootfs-overlay/bin으로 복사합니다."
# src 하위의 여러 폴더에서 빌드된 바이너리들을 찾아서 일괄 복사
find . -maxdepth 2 -type f -executable -not -name "Makefile" -not -name "*.cmake" -exec cp {} "$OVERLAY_BIN_DIR/" \;

cd $FAST_VOLUME

# ==============================================================================
# [2] BusyBox 소스 다운로드 및 가속 빌드
# ==============================================================================
echo "🌐 [2/5] BusyBox 소스 검증 및 빌드 시작..."

if [ ! -d "$BUSYBOX_DIR" ]; then
    echo "📥 BusyBox 소스코드가 없습니다. Git 복제 중..."
    git clone --depth 1 --branch 1_38_0 git://busybox.net/busybox.git "$BUSYBOX_DIR"
fi

cd "$BUSYBOX_DIR"
make defconfig

# 필수 데몬 기능 커스텀 활성화
for option in STATIC INIT FEATURE_USE_INITTAB FEATURE_INIT_SCTTY; do
    sed "s/^# CONFIG_${option} is not set/CONFIG_${option}=y/" .config > .config.tmp
    mv .config.tmp .config
done

# 가속 볼륨의 임시 rootfs 구조 생성 부위로 직접 인스톨
mkdir -p "$ROOTFS_DIR"
make -j$(nproc) install CONFIG_PREFIX="$ROOTFS_DIR"
cd $FAST_VOLUME

# ==============================================================================
# [3] Minimal RootFS 뼈대 생성 및 스크립트 자동화 (& 반영)
# ==============================================================================
echo "📦 [3/5] 램디스크(RootFS) 시스템 디렉터리 구성..."

cd "$ROOTFS_DIR"
# 호스트의 rootfs-overlay(우리가 방금 빌드한 정적 바이너리 포함)가 있으면 덮어쓰기
if [ -d "$HOST_WORKSPACE/rootfs-overlay" ]; then
    echo "📂 호스트의 rootfs-overlay 설정을 반영합니다."
    cp -R $HOST_WORKSPACE/rootfs-overlay/. ./
    # 실행 권한 부여
    chmod +x init etc/init.d/rcS etc/init.d/rcK
fi

# initramfs.cpio.gz 압축 패키징 수행
echo "🗜️ initramfs.cpio.gz 아카이브 생성 중..."
find . -print0 | cpio --null -ov --format=newc | gzip -9 > "$OUT_DIR/initramfs.cpio.gz"
cd $FAST_VOLUME

# ==============================================================================
# [4] Linux Kernel 다운로드 및 초고속 빌드
# ==============================================================================
echo "🛠️ [4/5] 리눅스 커널 컴파일 검증 및 시작..."

# 비정상 다운로드로 인해 Makefile이 누락된 찌꺼기 폴더 구제
if [ -d "$KERNEL_DIR" ] && [ ! -f "$KERNEL_DIR/Makefile" ]; then
    echo "⚠️ 기존 커널 폴더가 손상되어 재접속 처리를 위해 삭제합니다."
    rm -rf "$KERNEL_DIR"
fi

if [ ! -d "$KERNEL_DIR" ]; then
    echo "📥 리눅스 커널 소스코드를 Git에서 가져오는 중 (v7.3)..."
    git clone --branch v7.3 --single-branch --depth 1 \
        --config pack.windowMemory=10m --config pack.packSizeLimit=20m \
        --progress https://github.com "$KERNEL_DIR"
        
    if [ ! -f "$KERNEL_DIR/Makefile" ]; then
        echo "❌ [에러] 리눅스 커널 다운로드에 실패했습니다. 네트워크를 확인하세요."
        exit 1
    fi
fi

cd "$KERNEL_DIR"
make defconfig

echo "🚀 전체 코어 정밀 병렬 커널 컴파일 진행 중..."
make -j$(nproc) Image
cp arch/arm64/boot/Image "$OUT_DIR/Image"
cd $FAST_VOLUME

# ==============================================================================
# [5] 빌드 완료 프로세스 종료
# ==============================================================================
echo "========================================================================"
echo "✅ [5/5] 모든 단계 가속 빌드가 성공적으로 끝났습니다!"
echo "📂 결과물 위치 (출력 디렉터리): $OUT_DIR"
ls -lh "$OUT_DIR"
echo "========================================================================"
