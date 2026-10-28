#!/bin/bash
set -e

# (주의) 이 스크립트가 참조하는 rootfs-overlay 폴더는 맥북 마운트 영역(/home/developer/rootfs-overlay)에 있습니다.
HOST_WORKSPACE="/home/developer"

echo "👉 [도커 내부] 초고속 볼륨 영역으로 이동합니다."
# 🔥 맥북 폴더 연동을 끊고 도커 전용 볼륨 영역 안으로 들어가서 작업 개시
cd /build_fast

# 결과물과 소스코드를 담을 폴더 준비
mkdir -p src out

# A. BusyBox 자동 다운로드 (고속 볼륨 내부에서 수행)
BUSYBOX_DIR="src/busybox-1.38.0"
if [ ! -d "$BUSYBOX_DIR" ]; then
    echo "🌐 [도커 내부] BusyBox 소스코드가 없습니다. Git에서 가져오는 중..."
    git clone --depth 1 --branch 1_38_0 git://busybox.net/busybox.git "$BUSYBOX_DIR"
fi

# B. Linux Kernel 자동 다운로드 (고속 볼륨 내부에서 수행)
KERNEL_DIR="src/linux-7.2.6"
if [ ! -d "$KERNEL_DIR" ]; then
    echo "🌐 [도커 내부] 리눅스 커널 소스코드가 없습니다. Git에서 가져오는 중..."
    git clone --depth 1 --branch v7.2.6 https://github.com/torvalds/linux.git "$KERNEL_DIR"
fi

# --------------------------------------------------
# 램디스크(Minimal RootFS) 기본 구조 생성
# --------------------------------------------------
echo "📦 [도커 내부] 1. 램디스크 디렉터리 구조 생성..."
rm -rf rootfs
mkdir -p rootfs/bin rootfs/sbin rootfs/usr/bin rootfs/usr/sbin
mkdir -p rootfs/dev rootfs/etc rootfs/proc rootfs/sys rootfs/root

# BusyBox 컴파일 및 설치 (고속 볼륨 안이라 엄청나게 빨라집니다)
echo "🛠️ [도커 내부] BusyBox 빌드 시작..."
cd "$BUSYBOX_DIR"
make defconfig
for option in STATIC INIT FEATURE_USE_INITTAB FEATURE_INIT_SCTTY; do
    sed "s/^# CONFIG_${option} is not set/CONFIG_${option}=y/" .config > .config.tmp
    mv .config.tmp .config
done
make -j$(nproc) install CONFIG_PREFIX=../../rootfs
cd ../..

# ✨ 주의: 덮어쓸 오버레이 설정 파일은 맥북 호스트 영역에서 안전하게 가져옵니다.
if [ -d "$HOST_WORKSPACE/rootfs-overlay" ]; then
    cp -R $HOST_WORKSPACE/rootfs-overlay/. rootfs/
    chmod +x rootfs/init rootfs/etc/init.d/rcS
fi

# initramfs 압축 패키징
echo "📦 [도커 내부] initramfs.cpio.gz 생성..."
cd rootfs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../out/initramfs.cpio.gz
cd ..

# --------------------------------------------------
# 리눅스 커널 빌드
# --------------------------------------------------
echo "🛠️ [도커 내부] 리눅스 커널 컴파일 시작..."
cd "$KERNEL_DIR"
make defconfig
# nproc(M1 코어 전체)를 활용해 독립 볼륨 내에서 병렬로 초고속 빌드 진행
make -j$(nproc) Image
cp arch/arm64/boot/Image ../../out/Image
cd ../..

echo "✅ [도커 내부] 모든 가속 빌드가 끝났습니다."
