#!/bin/bash
set -e

cd "$(dirname "$0")"

# macOS에서 직접 호출해도 Linux 빌드 도구는 Docker 안에서 실행합니다.
if [ "$(uname -s)" = "Darwin" ]; then
    echo "👉 macOS에서 실행되었습니다. Docker 빌드를 시작합니다."
    exec /bin/bash ./build.sh
fi

echo "👉 [도커 내부] 빌드 작업을 시작합니다."
for source_dir in src/busybox-1.38.0 src/linux-7.2.6; do
    if [ ! -d "$source_dir" ]; then
        echo "❌ 소스 디렉터리가 없습니다: $source_dir" >&2
        exit 1
    fi
done
mkdir -p out

# --------------------------------------------------
# A. 램디스크(Minimal RootFS) 기본 구조 생성
# --------------------------------------------------
echo "📦 [도커 내부] 1. 램디스크 디렉터리 구조 생성..."
rm -rf rootfs
mkdir -p rootfs/bin rootfs/sbin rootfs/usr/bin rootfs/usr/sbin
mkdir -p rootfs/dev rootfs/etc rootfs/proc rootfs/sys rootfs/root

# BusyBox 1.38.0 컴파일 및 설치
if [ -d "src/busybox-1.38.0" ]; then
    echo "🛠️ [도커 내부] BusyBox 1.38.0 빌드 시작..."
    cd src/busybox-1.38.0
    make defconfig
    # 정적 빌드 옵션 활성화
    for option in STATIC INIT FEATURE_USE_INITTAB FEATURE_INIT_SCTTY; do
        sed "s/^# CONFIG_${option} is not set/CONFIG_${option}=y/" .config > .config.tmp
        mv .config.tmp .config
        grep -qx "CONFIG_${option}=y" .config || {
            echo "❌ BusyBox 필수 설정 누락: CONFIG_${option}" >&2
            exit 1
        }
    done
    make -j$(nproc) install CONFIG_PREFIX=../../rootfs
    cd ../..
    echo "✅ [도커 내부] BusyBox 1.38.0 설치 완료!"
else
    echo "❌ BusyBox 소스가 없습니다." >&2
    exit 1
fi

# Git으로 관리하는 초기화 파일을 rootfs에 설치
# /init → BusyBox init(PID 1) → inittab → rcS → 콘솔 셸
cp -R rootfs-overlay/. rootfs/
chmod +x rootfs/init rootfs/etc/init.d/rcS

# initramfs 압축 패키징
echo "📦 [도커 내부] initramfs.cpio.gz 생성..."
cd rootfs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../out/initramfs.cpio.gz
cd ..

# --------------------------------------------------
# B. 리눅스 커널 빌드 (src/linux-7.2.6)
# --------------------------------------------------
if [ -d "src/linux-7.2.6" ]; then
    echo "🛠️ [도커 내부] 리눅스 커널(v7.2.6) 컴파일 시작..."
    cd src/linux-7.2.6
    make defconfig
    make -j$(nproc) Image
    cp arch/arm64/boot/Image ../../out/Image
    cd ../..
    echo "✅ [도커 내부] 커널 빌드 완료!"
else
    echo "❌ [에러] src/linux-7.2.6 폴더를 찾을 수 없습니다. 커널 빌드를 수행하지 못했습니다."
    exit 1
fi

echo "✅ [도커 내부] 모든 빌드가 끝났습니다."

