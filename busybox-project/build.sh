#!/bin/bash
set -e

IMAGE_NAME="linux-builder-env"
CONTAINER_NAME="linux-builder-run"
WORKSPACE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$WORKSPACE_DIR"

# 🔥 속도 개선 핵심: 대량 컴파일 성능 저하를 막기 위한 도커 전용 고속 볼륨
VOLUME_NAME="linux-build-cache"

echo "🚀 [1/5] 도커 빌드 환경 이미지 생성/업데이트 중..."
docker build -f dockerfile -t "$IMAGE_NAME" .

echo "📦 [2/5] 기존 잔여 컨테이너 및 캐시 볼륨 확인..."
docker rm -f $CONTAINER_NAME 2>/dev/null || true
docker volume create $VOLUME_NAME > /dev/null

# 권한 뒤틀림 방지: 캐시 볼륨의 소유권을 도커 내부 일반 유저(developer)로 변경
docker run --rm --user root \
  -v "$VOLUME_NAME":/build_fast \
  "$IMAGE_NAME" /bin/sh -c 'chown developer:developer /build_fast'

echo "🛠️ [3/5] 도커 컨테이너 구동 및 초고속 내부 빌드 시작..."
# 호스트 폴더(-v $WORKSPACE_DIR)는 스크립트 실행용으로만 마운트하고,
# 실제 헤비한 컴파일은 컨테이너 전용 고속 볼륨(/build_fast) 내에서 수행하도록 이중 마운트합니다.
docker run --name "$CONTAINER_NAME" \
  -v "$WORKSPACE_DIR":/home/developer \
  -v "$VOLUME_NAME":/build_fast \
  $IMAGE_NAME /bin/bash /home/developer/container_build.sh

echo "🚚 [4/5] 가상 내부 볼륨에서 완성된 최종 산출물(out/) 추출 중..."
mkdir -p ./out

# 빌드가 끝난 후 고속 가상 볼륨(/build_fast)에 저장된 결과물 파일만 맥북으로 쏙 꺼내옵니다.
docker cp -L "$CONTAINER_NAME:/build_fast/out/Image" "./out/Image" 2>/dev/null || echo "⚠️ Image 복사 실패"
docker cp -L "$CONTAINER_NAME:/build_fast/out/initramfs.cpio.gz" "./out/initramfs.cpio.gz" 2>/dev/null || echo "⚠️ initramfs 복사 실패"

echo "🧹 [5/5] 사용이 끝난 임시 컨테이너 청소..."
docker rm -f $CONTAINER_NAME

echo "🎉 속도 개선 빌드가 완료되었습니다! 'out' 폴더를 확인하세요."
