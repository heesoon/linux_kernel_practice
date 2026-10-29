cmake_minimum_required(VERSION 3.10)
project(SysTestApp LANGUAGES CXX)

# 빌드 타입이 지정되지 않은 경우 최적화(Release) 모드로 기본 설정 (-O2 효과)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# ----------------------------------------------------------------=====
# 💡 하위 타겟 전용 정적(Static) 링크 및 스레드 라이브러리 설정
# ----------------------------------------------------------------=====
set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
set(BUILD_SHARED_LIBS OFF)

# 소스 파일 및 실행 파일(타겟) 정의
add_executable(sys_test_app app1.cpp)

# pthread(스레드) 라이브러리 안전하게 링크
find_package(Threads REQUIRED)
target_link_libraries(sys_test_app PRIVATE Threads::Threads)

# ----------------------------------------------------------------=====
# ✨ 빌드 완료 후 자동으로 rootfs-overlay/bin 폴더로 복사 및 권한 부여
# ----------------------------------------------------------------=====
# 변수를 활용해 경로 관리 (상위 변수가 없다면 기본 도커 경로 사용)
if(NOT HOST_WORKSPACE)
    set(HOST_WORKSPACE "/home/developer")
endif()
set(OVERLAY_BIN_DIR "${HOST_WORKSPACE}/rootfs-overlay/bin")

add_custom_command(TARGET sys_test_app POST_BUILD
    # 1. 타겟 디렉터리가 없으면 자동 생성
    COMMAND ${CMAKE_COMMAND} -E make_directory "${OVERLAY_BIN_DIR}"
    # 2. 빌드된 실행 파일을 rootfs-overlay/bin 으로 복사 (타겟 이름 유연하게 반영)
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:sys_test_app> "${OVERLAY_BIN_DIR}/$<TARGET_FILE_NAME:sys_test_app>"
    # 3. 리눅스/맥 환경에서 실행 가능하도록 권한(Chmod +x) 변경
    COMMAND chmod +x "${OVERLAY_BIN_DIR}/$<TARGET_FILE_NAME:sys_test_app>"
    COMMENT "🚚 Copying $<TARGET_FILE_NAME:sys_test_app> to host rootfs-overlay/bin..."
)
