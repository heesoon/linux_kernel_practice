# 1. ARM64 Ubuntu 환경 지정 (맥북 네이티브 아키텍처)
FROM --platform=linux/arm64 ubuntu:22.04

# 2. 휴먼 인터랙션 방지 설정
ENV DEBIAN_FRONTEND=noninteractive

# 3. 리눅스 커널 및 램디스크 빌드 필수 패키지 설치
RUN apt-get update && apt-get install -y \
    build-essential \
    libncurses-dev \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    bc \
    git \
    wget \
    cpio \
    kmod \
    rsync \
    vim \
    curl \
    sudo \
    unzip \
    && apt-get clean

# 4. 일반 사용자 계정 생성 (맥북 호스트와 파일 권한 꼬임 방지)
RUN useradd -m -s /bin/bash developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER developer
WORKDIR /home/developer

# 5. 기본 실행 명령
CMD ["/bin/bash"]
