#!/bin/bash
set -e

IMAGE_NAME="buildroot-builder-env"
CONTAINER_NAME="buildroot-builder-run"
WORKSPACE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$WORKSPACE_DIR"

# Buildroot 대량 컴파일 성능 저하를 막기 위한 독립 명명 볼륨
VOLUME_NAME="buildroot-cache-volume"

echo "🚀 [1/5] 도커 빌드 환경 이미지 생성/업데이트 중..."
docker build -f dockerfile -t "$IMAGE_NAME" .

echo "📦 [2/5] 기존 잔여 컨테이너 및 캐시 볼륨 확인..."
docker rm -f $CONTAINER_NAME 2>/dev/null || true
docker volume create $VOLUME_NAME > /dev/null

# 명명 볼륨은 기본적으로 root 소유여서 developer의 git clone이 Permission denied로 실패합니다.
# 빌드 전에 캐시 볼륨의 최상위 디렉터리만 developer 소유로 변경합니다.
# 실제 소스 다운로드와 컴파일은 기존처럼 일반 사용자 developer로 실행합니다.
docker run --rm --user root \
  -v "$VOLUME_NAME":/build_fast \
  "$IMAGE_NAME" /bin/sh -c 'chown developer:developer /build_fast'

echo "🛠️ [3/5] 도커 컨테이너 구동 및 Buildroot 컴파일 시작..."
# 스크립트와 아웃풋 제어를 위해 워크스페이스를 마운트하되, 
# 실제 Buildroot 소스 다운로드와 헤비한 컴파일은 컨테이너 전용 고속 볼륨(/build_fast) 내에서 수행합니다.
docker run --name $CONTAINER_NAME \
  -v "$WORKSPACE_DIR":/home/developer \
  -v "$VOLUME_NAME":/build_fast \
  $IMAGE_NAME /bin/bash /home/developer/container_build.sh

echo "🚚 [4/5] 가상 내부 볼륨에서 완성된 최종 산출물(out/) 추출 중..."
# 컴파일 완료 후 컨테이너 내부 내부 가속 공간에서 나온 핵심 이미지들만 호스트 out/ 폴더로 복사합니다.
mkdir -p ./out
docker cp $CONTAINER_NAME:/build_fast/buildroot/output/images/Image ./out/Image 2>/dev/null || true
docker cp $CONTAINER_NAME:/build_fast/buildroot/output/images/rootfs.ext4 ./out/rootfs.ext4 2>/dev/null || true

echo "🧹 [5/5] 사용이 끝난 임시 컨테이너 및 찌꺼기 청소..."
docker rm -f $CONTAINER_NAME
docker image prune -f

echo "🎉 과정이 깔끔하게 완료되었습니다! 'out' 폴더의 Image와 rootfs.ext4를 확인하세요."