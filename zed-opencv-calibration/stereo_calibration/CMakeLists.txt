cmake_minimum_required(VERSION 3.5)
project(zed_stereo_calibration)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_BUILD_TYPE "Release")

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(ZED 5 REQUIRED)
find_package(OpenCV REQUIRED)
find_package(CUDA ${ZED_CUDA_VERSION} REQUIRED)
find_package(yaml-cpp REQUIRED)

include_directories(${CUDA_INCLUDE_DIRS})
include_directories(${ZED_INCLUDE_DIRS})
include_directories(${OpenCV_INCLUDE_DIRS})
include_directories(${YAML_CPP_INCLUDE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

link_directories(${ZED_LIBRARY_DIR})
link_directories(${OpenCV_LIBRARY_DIRS})
link_directories(${CUDA_LIBRARY_DIRS})

FILE(GLOB_RECURSE SRC_FILES "src/*.cpp")
FILE(GLOB_RECURSE HDR_FILES "include/*.hpp")
set(CALIBRATION_SOURCES
    src/main.cpp
    src/opencv_calibration.cpp
    src/calibration_checker.cpp
)

add_executable(${PROJECT_NAME} ${HDR_FILES} ${CALIBRATION_SOURCES})

add_executable(zed_print_camera_intrinsics src/print_camera_intrinsics.cpp)

TARGET_LINK_LIBRARIES(${PROJECT_NAME} ${ZED_LIBRARIES} ${CUDA_LIBRARIES} ${OpenCV_LIBRARIES} yaml-cpp)
target_link_libraries(zed_print_camera_intrinsics ${ZED_LIBRARIES} ${CUDA_LIBRARIES})

# Ship the example config alongside the binary so the user can do:
#   zed_stereo_calibration --config /opt/zed-opencv-calibration/stereo_calibration/config/fisheye_stereo.yaml
install(DIRECTORY config/ DESTINATION share/${PROJECT_NAME}/config FILES_MATCHING PATTERN "*.yaml")

