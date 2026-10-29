# src/CMakeLists.txt
cmake_minimum_required(VERSION 3.10)
project(LinuxUserApplications CXX)

set(CMAKE_CXX_STANDARD 17)

# 🔥 [핵심] 미니멀 램디스크 환경을 위해 전체 프로젝트에 정적 링크를 강제합니다.
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static") 
set(BUILD_SHARED_LIBS OFF)

# 하위 앱 디렉터리 연결
add_subdirectory(app)
