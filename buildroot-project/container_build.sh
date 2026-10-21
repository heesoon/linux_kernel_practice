#!/bin/bash
set -e

echo "📥 [Inside Docker] Buildroot 최신 소스 다운로드 확인 중..."
cd /build_fast
if [ ! -d "buildroot" ]; then
    # 기본 브랜치의 최신 개발 소스를 얕은 복사로 다운로드
    git clone --depth=1 https://gitlab.com/buildroot.org/buildroot.git buildroot
fi

cd buildroot

# 만약 이전에 저장해둔 defconfig가 호스트 폴더에 있다면 컨테이너 안으로 로드
if [ -f "/home/developer/configs/buildroot_defconfig" ]; then
    echo "⚙️ [Inside Docker] 기존 보관된 빌드 설정(.config)을 적용합니다."
    cp /home/developer/configs/buildroot_defconfig ./configs/my_defconfig
    make my_defconfig
else
    echo "⚙️ [Inside Docker] 저장된 설정이 없습니다. 최초 수동 설정을 시작합니다..."
    echo "💡 메뉴 진입 후 Target(AArch64), Init(systemd), Package(dropbear)를 세팅하세요."
    make menuconfig
    
    # 수동 설정 결과를 나중에 재사용할 수 있도록 호스트에 박제
    mkdir -p /home/developer/configs
    make savedefconfig BR2_DEFCONFIG=/home/developer/configs/buildroot_defconfig
fi

echo "🚀 [Inside Docker] 원클릭 통합 빌드 컴파일을 시작합니다 (-j$(nproc))..."
make -j$(nproc)

echo "✅ [Inside Docker] 컴파일 종료."