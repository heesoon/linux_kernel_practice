#!/bin/bash
set -e

cd "$(dirname "$0")"

# macOS에서 직접 호출해도 Linux 빌드 도구는 Docker 안에서 실행합니다.
if [ "$(uname -s)" = "Darwin" ]; then
    echo "👉 macOS에서 실행되었습니다. Docker 빌드를 시작합니다."
    exec /bin/bash ./build.sh
fi

echo "👉 [도커 내부] 빌드 작업을 시작합니다."

# --------------------------------------------------
# 0. 소스코드 Git 자동 다운로드 (완전 자동화 추가)
# --------------------------------------------------
mkdir -p src
mkdir -p out

# A. BusyBox 자동 다운로드 (Stable 1_38_0 태그 기준)
BUSYBOX_DIR="src/busybox-1.38.0"
if [ ! -d "$BUSYBOX_DIR" ]; then
    echo "🌐 [도커 내부] BusyBox 소스코드가 없습니다. Git에서 가져오는 중..."
    # --depth 1과 --branch 옵션으로 필요한 버정 정보만 빠르게 다운로드 [1, 2]
    git clone --depth 1 --branch 1_38_0 https://github.com "$BUSYBOX_DIR"
else
    echo "📦 [도커 내부] BusyBox 소스코드가 이미 존재합니다."
fi

# B. Linux Kernel 자동 다운로드 (v7.2.6이 존재하지 않으므로, 최신 장기 지원 버전인 v6.6 stable 예시)
# 💡 실제 원하시는 버전의 태그명으로 --branch 부분을 변경하시면 됩니다.
KERNEL_DIR="src/linux-7.2.6"
if [ ! -d "$KERNEL_DIR" ]; then
    echo "🌐 [도커 내부] 리눅스 커널 소스코드가 없습니다. Git에서 가져오는 중..."
    # 커널은 용량이 매우 크므로 --depth 1이 필수입니다. [1, 2]
    git clone --depth 1 --branch v6.6 https://kernel.org "$KERNEL_DIR"
else
    echo "📦 [도커 내부] 리눅스 커널 소스코드가 이미 존재합니다."
fi


# --------------------------------------------------
# A. 램디스크(Minimal RootFS) 기본 구조 생성
# --------------------------------------------------
echo "📦 [도커 내부] 1. 램디스크 디렉터리 구조 생성..."
rm -rf rootfs
mkdir -p rootfs/bin rootfs/sbin rootfs/usr/bin rootfs/usr/sbin
mkdir -p rootfs/dev rootfs/etc rootfs/proc rootfs/sys rootfs/root

# BusyBox 컴파일 및 설치
echo "🛠️ [도커 내부] BusyBox 빌드 시작..."
cd "$BUSYBOX_DIR"
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
echo "✅ [도커 내부] BusyBox 설치 완료!"

# Git으로 관리하는 초기화 파일을 rootfs에 설치
cp -R rootfs-overlay/. rootfs/
chmod +x rootfs/init rootfs/etc/init.d/rcS

# initramfs 압축 패키징
echo "📦 [도커 내부] initramfs.cpio.gz 생성..."
cd rootfs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../out/initramfs.cpio.gz
cd ..

# --------------------------------------------------
# B. 리눅스 커널 빌드
# --------------------------------------------------
echo "🛠️ [도커 내부] 리눅스 커널 컴파일 시작..."
cd "$KERNEL_DIR"
make defconfig
make -j$(nproc) Image
cp arch/arm64/boot/Image ../../out/Image
cd ../..
echo "✅ [도커 내부] 커널 빌드 완료!"

echo "✅ [도커 내부] 모든 빌드가 끝났습니다."
