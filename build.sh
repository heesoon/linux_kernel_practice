#!/bin/bash
set -e

IMAGE_NAME="linux-builder-env"
CONTAINER_NAME="linux-builder-run"
WORKSPACE_DIR="$(pwd)"

echo "🚀 [1/4] 도커 빌드 환경 이미지 생성/업데이트 중..."
docker build -t $IMAGE_NAME .

echo "📦 [2/4] 기존 잔여 컨테이너 정리..."
docker rm -f $CONTAINER_NAME 2>/dev/null || true

echo "🛠️ [3/4] 도커 컨테이너 구동 및 내부 빌드 스크립트 실행..."
# 맥북의 현재 폴더 전체가 마운트되므로 container_build.sh도 도커 안에서 그대로 실행 가능합니다.
docker run --name $CONTAINER_NAME \
  -v "$WORKSPACE_DIR":/home/developer \
  $IMAGE_NAME /bin/bash /home/developer/container_build.sh

echo "🧹 [4/4] 사용이 끝난 임시 컨테이너 및 찌꺼기 청소..."
docker rm -f $CONTAINER_NAME
docker image prune -f

echo "🎉 과정이 깔끔하게 완료되었습니다! 'out' 폴더를 확인하세요."
