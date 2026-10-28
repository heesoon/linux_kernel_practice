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
KERNEL_DIR="src/linux-7.3"

# [핵심 수정] 폴더는 존재하지만 안에 핵심 파일(Makefile)이 없다면 다운로드 실패작으로 간주하고 강제 삭제
if [ -d "$KERNEL_DIR" ] && [ ! -f "$KERNEL_DIR/Makefile" ]; then
    echo "⚠️  [도커 내부] 기존 커널 폴더가 비어있거나 손상되었습니다. 삭제 후 재시도합니다."
    rm -rf "$KERNEL_DIR"
fi

# 커널 소스가 없을 때만 다운로드 수행
if [ ! -d "$KERNEL_DIR" ]; then
    echo "🌐 [도커 내부] 리눅스 커널 소스코드를 Git에서 가져오는 중 (v7.3)..."
    
    # --depth 1 외에 다운로드 안정성을 높이기 위한 추가 옵션 부여
    # (공식 torvalds/linux 저장소는 브랜치가 아니라 '태그'이므로 -b 대신 정확히 v7.3 지정)
    git clone --branch v7.3 --single-branch --depth 1 \
              --config pack.windowMemory=10m --config pack.packSizeLimit=20m \
              --progress https://github.com/torvalds/linux.git "$KERNEL_DIR"
              
    # 다운로드가 성공했는지 한 번 더 검증
    if [ ! -f "$KERNEL_DIR/Makefile" ]; then
        echo "❌ [도커 내부 에러] 리눅스 커널 다운로드에 실패했습니다. 네트워크를 확인하세요."
        exit 1
    fi
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

# --------------------------------------------------
# ✨ [오류 수정] 오버레이 설정 파일 반영 및 누락 방지 자동 생성
# --------------------------------------------------
# 1. 만약 맥북 호스트 영역에 rootfs-overlay 폴더가 있다면 정상 복사
if [ -d "$HOST_WORKSPACE/rootfs-overlay" ]; then
    echo "📂 [도커 내부] 호스트의 rootfs-overlay 설정을 복사합니다."
    cp -R $HOST_WORKSPACE/rootfs-overlay/. rootfs/
fi

# 2. 만약 복사 후에도 rcS 파일이 없다면 (맥북에 폴더가 없었거나 비어있던 경우) 빌드 에러 방지를 위해 기본 생성
if [ ! -f "rootfs/etc/init.d/rcS" ]; then
    echo "⚠️  [도커 내부] rootfs/etc/init.d/rcS 파일이 없어 기본 초기화 스크립트를 자동 생성합니다."
    cat << 'EOF' > rootfs/etc/init.d/rcS
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
/bin/sh
EOF
fi

# 3. 만약 복사 후에도 상위 init 파일이 없다면 기본 생성
if [ ! -f "rootfs/init" ]; then
    echo "⚠️  [도커 내부] rootfs/init 파일이 없어 기본 init 스크립트를 자동 생성합니다."
    cat << 'EOF' > rootfs/init
#!/bin/sh
exec /sbin/init
EOF
fi

# 파일들이 무조건 존재하므로 더 이상 '파일이 없다'는 권한 오류(chmod)가 나지 않습니다.
chmod +x rootfs/init rootfs/etc/init.d/rcS

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
