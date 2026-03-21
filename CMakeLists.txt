cmake_minimum_required(VERSION 3.25)

project(new_engine VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Show compile commands" FORCE)

string(COMPARE EQUAL ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_SOURCE_DIR} PROJECT_IS_TOP_LEVEL)

# We only build shared libs (and therefore PIC) for python targets
if(ENGINE_BUILD_PYTHON)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    add_definitions(-DENGINE_ENABLE_PYTHON_BINDINGS)
endif()

# Only build and run tests if the project is top level
option(ENGINE_TEST "Build & run tests" "${PROJECT_IS_TOP_LEVEL}")

# Default to Debug build
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING
        "Choose the type of build, options are: Debug Release."
        FORCE)
endif()

# ---------------------------------------------------------------------------
# Build acceleration: ccache
# ---------------------------------------------------------------------------
option(WITH_CCACHE "Enable ccache, if available" ON)
if(WITH_CCACHE)
    find_program(CCACHE_CMD ccache)
    if(CCACHE_CMD)
        message(STATUS "ccache enabled: ${CCACHE_CMD}")
        set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ${CCACHE_CMD})
    else()
        message(STATUS "ccache not found, continuing without it")
    endif()
else()
    message(STATUS "ccache disabled")
endif()

# Symlink compile_commands.json to build dir for IDE support
if(CMAKE_GENERATOR STREQUAL "Unix Makefiles" OR CMAKE_GENERATOR STREQUAL "Ninja")
    set(SRC_LINK ${CMAKE_SOURCE_DIR}/_build/compile_commands.json)
    set(BLD_FILE ${CMAKE_BINARY_DIR}/compile_commands.json)
    if(EXISTS ${SRC_LINK} OR IS_SYMLINK ${SRC_LINK})
        file(REMOVE ${SRC_LINK})
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ${BLD_FILE} ${SRC_LINK})
endif()

# ---------------------------------------------------------------------------
# CMake modules
# ---------------------------------------------------------------------------
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/modules)

find_program(CMAKE_C_COMPILER NAMES $ENV{CC} clang gcc)
find_program(CMAKE_CXX_COMPILER NAMES $ENV{CXX} clang++ g++)
find_package(Threads REQUIRED)

include(Versioning)
include(EngineFlags)
include(SetupProtobuf)

extract_version_from_git()
message(STATUS "Project version: ${PROJECT_VERSION}")
add_definitions(-DPROJECT_VERSION="${PROJECT_VERSION}")

# ---------------------------------------------------------------------------
# Sanitizers
# ---------------------------------------------------------------------------
if(WITH_ASAN)
    add_compile_options($<$<COMPILE_LANGUAGE:CXX>:-fsanitize=address> $<$<COMPILE_LANGUAGE:CXX>:-fno-omit-frame-pointer>)
    link_libraries(-fsanitize=address)
endif()

if(WITH_TSAN)
    add_compile_options($<$<COMPILE_LANGUAGE:CXX>:-fsanitize=thread> $<$<COMPILE_LANGUAGE:CXX>:-fno-omit-frame-pointer>)
    link_libraries(-fsanitize=thread)
endif()

# ---------------------------------------------------------------------------
# Dependencies (all from public Conan / system packages)
# ---------------------------------------------------------------------------
find_package(GTest REQUIRED)
find_package(benchmark REQUIRED)
include(SetupTest)

if(ENABLE_CPP_TEST)
    message(STATUS "C++ testing is ENABLED")
else()
    message(STATUS "C++ testing is DISABLED")
endif()

find_package(absl REQUIRED)
find_package(Protobuf REQUIRED)
find_package(fmt REQUIRED)
find_package(spdlog REQUIRED)
find_package(RapidJSON REQUIRED CONFIG)
find_package(tsl-robin-map REQUIRED)
find_package(zstd REQUIRED)
find_package(ZLIB REQUIRED)

# Optional heavy deps — uncomment as needed
# find_package(Arrow REQUIRED)
# find_package(HDF5 REQUIRED)

# ---------------------------------------------------------------------------
# Python bindings (optional)
# ---------------------------------------------------------------------------
if(ENGINE_BUILD_PYTHON)
    set(Python_ROOT_DIR "${PYTHON_ROOT_DIR}")
    find_package(Python "${PY_VER_MAJMIN}"
        COMPONENTS Interpreter Development REQUIRED
        OPTIONAL_COMPONENTS Development.SABIModule)
    find_package(nanobind REQUIRED CONFIG)
    include(SetupPythonRegistry)
endif()

# ---------------------------------------------------------------------------
# Subdirectories
# ---------------------------------------------------------------------------
add_subdirectory(libs)
add_subdirectory(apps)

if(ENGINE_BUILD_PYTHON)
    create_pth_file()
    create_mypy_ini()
    finalize_python_paths()
endif()
