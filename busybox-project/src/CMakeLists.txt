cmake_minimum_required(VERSION 3.10)

# 프로젝트 이름 및 언어 설정
project(LinuxUserApplications LANGUAGES CXX)

# C++11 표준 요구 (모던 C++ 문법 사용)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_subdirectory(app)
