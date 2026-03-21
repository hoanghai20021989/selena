set(TARGET engine_core)

file(GLOB_RECURSE SOURCES src/*.cc src/*.cpp)
add_library(${TARGET} STATIC ${SOURCES})

target_include_directories(${TARGET} PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_BINARY_DIR}
)

target_link_libraries(${TARGET} PUBLIC
    engine_core_pb
    fmt::fmt
    spdlog::spdlog
    absl::strings
    absl::time
    tsl::robin_map
    Threads::Threads
)

# Precompiled headers (Clang only — GCC can OOM on complex TUs)
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_precompile_headers(${TARGET} PRIVATE
        <fmt/format.h>
        <spdlog/spdlog.h>
        <google/protobuf/message.h>
    )
endif()

if(ENABLE_CPP_TEST)
    add_subdirectory(test)
endif()
