cmake_minimum_required(VERSION 3.16)
project(LLVMPassLab)

find_package(LLVM REQUIRED CONFIG
    PATHS /usr/lib/llvm-21/lib/cmake/llvm NO_DEFAULT_PATH)

include(AddLLVM)
include_directories(${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

# IRScout — reconnaissance pass
add_library(IRScout SHARED IRScout.cpp)
target_compile_options(IRScout PRIVATE -fno-rtti)
set_target_properties(IRScout PROPERTIES PREFIX "" SUFFIX ".so")

