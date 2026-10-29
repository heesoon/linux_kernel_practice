cmake_minimum_required(VERSION 3.10)

# 프로젝트 이름 및 언어 설정
project(SysTestApp LANGUAGES CXX)

# C++11 표준 요구 (모던 C++ 문법 사용)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ----------------------------------------------------------------=====
# 💡 핵심 설정: 최소형 램디스크(RootFS) 환경을 위한 정적(Static) 링크 강제
# ----------------------------------------------------------------=====
# 1) 전체 타겟에 g++ -static 옵션 부여 효과
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")

# 2) CMake가 내부적으로 공유 라이브러리(.so)보다 정적 라이브러리(.a)를 우선 찾도록 설정
set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
set(BUILD_SHARED_LIBS OFF)

# 빌드 타입이 지정되지 않은 경우 최적화(Release) 모드로 기본 설정 (-O2 효과)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# 소스 파일 및 실행 파일(타겟) 정의
# (앞서 작성한 main.cpp 파일이 같은 폴더에 있다고 가정합니다)
add_executable(sys_test_app app1.cpp)

# 만약 pthread(쓰레드) 라이브러리가 필요하다면 안전하게 링크
find_package(Threads REQUIRED)
target_link_libraries(sys_test_app PRIVATE Threads::Threads)

# ----------------------------------------------------------------=====
# 설치(Install) 경로 정의 (기존 빌드 스크립트의 rootfs 복사용)
# ----------------------------------------------------------------=====
# 'make install' 명령을 내렸을 때 rootfs/usr/bin 폴더로 바로 들어가도록 설정
#install(TARGETS sys_test_app DESTINATION usr/bin)

# ----------------------------------------------------------------=====
# ✨ [요청 반영] 빌드 완료 후 rootfs-overlay/bin 폴더로 강제 복사 및 권한 부여
# ----------------------------------------------------------------=====
# 주석의 내용처럼 호스트(맥북)와 공유되는 /home/developer/rootfs-overlay/bin 경로를 타겟으로 잡습니다.
set(OVERLAY_BIN_DIR "/home/developer/rootfs-overlay/bin")

add_custom_command(TARGET sys_test_app POST_BUILD
    # 1. 타겟 디렉터리가 없으면 자동 생성
    COMMAND ${CMAKE_COMMAND} -E make_directory "${OVERLAY_BIN_DIR}"
    # 2. 빌드된 실행 파일을 rootfs-overlay/bin 으로 복사
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:sys_test_app> "${OVERLAY_BIN_DIR}/sys_test_app"
    # 3. 리눅스/맥 환경에서 실행 가능하도록 권한(Chmod +x) 변경
    COMMAND chmod +x "${OVERLAY_BIN_DIR}/sys_test_app"
    COMMENT "🚚 Copying sys_test_app to host rootfs-overlay/bin and setting executable permissions..."
)