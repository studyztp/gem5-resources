set(NUGGET_UTIL_PATH "${CMAKE_CURRENT_LIST_DIR}/../../nugget_util")

set(NUGGET_LIBRARY_PATH "${NUGGET_UTIL_PATH}/cmake")
set(NUGGET_HOOKS_PATH "${NUGGET_UTIL_PATH}/hook_helper")
set(NUGGET_C_HOOKS_PATH "${NUGGET_HOOKS_PATH}/c_hooks")

if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
    message("Architecture is 64-bit.")
    set(PAPI_PATH "${NUGGET_HOOKS_PATH}/other_tools/papi/x86_64")
    set(M5_PATH "${NUGGET_HOOKS_PATH}/other_tools/gem5/x86")

elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
    message("Architecture is ARM.")
    set(PAPI_PATH "${NUGGET_HOOKS_PATH}/other_tools/papi/aarch64")
    set(M5_PATH "${NUGGET_HOOKS_PATH}/other_tools/gem5/arm64")
else()
    message("Unknown architecture: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

set(M5_INCLUDE_PATH "${NUGGET_HOOKS_PATH}/other_tools/gem5/include")

set(LLVM_BC_DIR "${CMAKE_CURRENT_BINARY_DIR}/llvm-bc")

# set if we should use addr mop m5 ops in the beginning and end of the ROI
# for
set(IF_USE_ADDR_VERSION_M5OPS_BEGIN TRUE)
set(IF_USE_ADDR_VERSION_M5OPS_END TRUE)

set(LLVM_ROOT "/usr/lib/llvm-18")
set(LLVM_BIN "${LLVM_ROOT}/bin")

set(EXTRA_FLAGS "-lm" "-fopenmp" "-DUSE_NUGGET")
