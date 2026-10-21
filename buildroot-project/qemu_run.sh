#!/bin/bash
set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$WORKSPACE_DIR"

if ! command -v qemu-system-aarch64 >/dev/null 2>&1; then
  echo "❌ qemu-system-aarch64가 필요합니다. macOS: brew install qemu" >&2
  exit 1
fi
for artifact in out/Image out/rootfs.ext4; do
  if [ ! -s "$artifact" ]; then
    echo "❌ $artifact 파일이 없거나 비어 있습니다. 먼저 bash build.sh를 실행하세요." >&2
    exit 1
  fi
done

echo "🐧 ARM64 Buildroot 부팅 (종료: Ctrl+A를 누른 뒤 X)"
echo "SSH 포워딩: localhost:2222 → 게스트:22 (게스트 네트워크와 로그인 설정 필요)"
exec qemu-system-aarch64 \
  -machine virt \
  -cpu cortex-a57 \
  -smp 4 \
  -m 2048 \
  -kernel out/Image \
  -drive file=out/rootfs.ext4,format=raw,if=none,id=rootfs \
  -device virtio-blk-device,drive=rootfs \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 \
  -device virtio-net-device,netdev=net0 \
  -nographic \
  -append "console=ttyAMA0 root=/dev/vda rootfstype=ext4 rw rootwait"
