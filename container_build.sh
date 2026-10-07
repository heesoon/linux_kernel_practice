#!/bin/bash
set -e

echo "👉 [도커 내부] 빌드 작업을 시작합니다."
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
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
    make -j$(nproc) install CONFIG_PREFIX=../../rootfs
    cd ../..
    echo "✅ [도커 내부] BusyBox 1.38.0 설치 완료!"
else
    echo "⚠️ [안내] src/busybox-1.38.0 폴더가 없어 기본 쉘만 링크합니다."
    ln -sf /bin/sh rootfs/bin/sh
fi

# 고도화된 init 파일 생성
echo "📝 [도커 내부] init 스크립트 생성..."
cat << 'EOF' > rootfs/init
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || true

echo ""
echo "=========================================="
echo "    WELCOME TO MY BUSYBOX 1.38.0 LINUX    "
echo "=========================================="
echo ""

exec /bin/sh
EOF
chmod +x rootfs/init

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

