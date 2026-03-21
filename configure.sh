#!/bin/bash -e

function usage {
    cat<<EOF
Usage: $0 [options]

Helper that initializes your working directory.

Options:
--clang               Use system clang for compilation [default, only supported compiler]
--debug               Create workspace for Debug build [default]
--release             Create workspace for Release build
--python              Build Python bindings [default: off]
--no-cpp-test         Disable C++ test targets
--no-python-test      Disable Python test targets
--asan                Enable Address Sanitizer
--tsan                Enable Thread Sanitizer
--enable-ccache       Enable ccache [default: on]
--disable-ccache      Disable ccache
--with-clang-tidy     Enable clang-tidy
--time-trace          Enable Clang compilation time analysis
--skip-conan          Skip Conan dependency resolution
--wipe                Wipe build workspace
--verbose             Run in verbose mode
EOF
}

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
ENABLE_PYTHON="${ENABLE_PYTHON:-0}"
ENABLE_CPP_TEST="${ENABLE_CPP_TEST:-1}"
ENABLE_PYTHON_TEST="${ENABLE_PYTHON_TEST:-1}"
ENABLE_CCACHE="${ENABLE_CCACHE:-1}"
COMPILER="${COMPILER:-clang}"
BUILD_TYPE="${BUILD_TYPE:-Debug}"
WIPE=0
SKIP_CONAN=0
CMAKE_FLAGS=""

# ---------------------------------------------------------------------------
# Parse CLI
# ---------------------------------------------------------------------------
while test $# -gt 0; do
    case "$1" in
        -h|--help)       usage; exit 0 ;;
        --python)        ENABLE_PYTHON=1; shift ;;
        --clang)         COMPILER=clang; shift ;;
        --debug)         BUILD_TYPE=Debug; shift ;;
        --release)       BUILD_TYPE=Release; shift ;;
        --no-cpp-test)   ENABLE_CPP_TEST=0; shift ;;
        --no-python-test) ENABLE_PYTHON_TEST=0; shift ;;
        --asan)          CMAKE_FLAGS="${CMAKE_FLAGS} -DWITH_ASAN=1"; shift ;;
        --tsan)          CMAKE_FLAGS="${CMAKE_FLAGS} -DWITH_TSAN=1"; shift ;;
        --enable-ccache) ENABLE_CCACHE=1; shift ;;
        --disable-ccache) ENABLE_CCACHE=0; shift ;;
        --with-clang-tidy) export WITH_CLANG_TIDY=1; shift ;;
        --time-trace)    export TIME_TRACE=1; shift ;;
        --skip-conan)    SKIP_CONAN=1; shift ;;
        --wipe)          WIPE=1; shift ;;
        --verbose)       set -x; shift ;;
        *)               break ;;
    esac
done

CMAKE_FLAGS="${CMAKE_FLAGS} -DWITH_CCACHE=${ENABLE_CCACHE} -DENGINE_BUILD_PYTHON=${ENABLE_PYTHON} -DENABLE_CPP_TEST=${ENABLE_CPP_TEST} -DENABLE_PYTHON_TEST=${ENABLE_PYTHON_TEST}"

# ---------------------------------------------------------------------------
# Detect compiler
# ---------------------------------------------------------------------------
export CXX="${CXX:-$(command -v clang++ 2>/dev/null || echo clang++)}"
export CC="${CC:-$(command -v clang 2>/dev/null || echo clang)}"
COMPILER_TAG="clang"

echo "Using compiler: CC=$CC  CXX=$CXX"

# ---------------------------------------------------------------------------
# Build directory
# ---------------------------------------------------------------------------
BUILD_DIR="${BUILD_DIR:-_build}"
BUILD_TYPE_DIR="${BUILD_DIR}/${COMPILER_TAG}_${BUILD_TYPE}"

if [[ $WIPE -ne 0 ]]; then
    echo "Wiping workspace at ${BUILD_TYPE_DIR}"
    rm -rf "${BUILD_TYPE_DIR}"
fi

mkdir -p "${BUILD_TYPE_DIR}/log"

echo "Configuring build environment at: ${BUILD_TYPE_DIR}"

# ---------------------------------------------------------------------------
# Python virtual environment
# ---------------------------------------------------------------------------
PYTHON_BIN="${PYTHON_BIN:-python3}"
VENV_PATH="${BUILD_TYPE_DIR}/venv"

echo "Setting up Python virtual environment..."
${PYTHON_BIN} -m venv --system-site-packages "${VENV_PATH}"
rm -f _venv
ln -sT "${VENV_PATH}" "_venv"
source "${VENV_PATH}/bin/activate"

# Install requirements
if [[ -f "devtools/python/requirements.txt" ]]; then
    pip install -q -r "devtools/python/requirements.txt"
fi

# ---------------------------------------------------------------------------
# Conan
# ---------------------------------------------------------------------------
pip install -q "conan>=2.0"

if [[ $SKIP_CONAN -eq 0 ]]; then
    # Detect default Conan profile or create one
    conan profile detect --exist-ok

    # Detect clang version
    CLANG_VERSION=$($CXX --version | head -1 | grep -oP '\d+\.\d+\.\d+' | head -1)
    CLANG_MAJOR=$(echo "$CLANG_VERSION" | cut -d. -f1)
    echo "Detected clang version: ${CLANG_VERSION} (major: ${CLANG_MAJOR})"

    # Ensure public ConanCenter is available
    conan remote add conancenter https://center2.conan.io 2>/dev/null || true

    CONAN_INSTALL_CMD="conan install --output-folder=${BUILD_TYPE_DIR} -r conancenter"
    CONAN_INSTALL_CMD+=" -s build_type=${BUILD_TYPE}"
    CONAN_INSTALL_CMD+=" -s compiler=clang"
    CONAN_INSTALL_CMD+=" -s compiler.version=${CLANG_MAJOR}"
    CONAN_INSTALL_CMD+=" -s compiler.libcxx=libstdc++11"
    CONAN_INSTALL_CMD+=" -s compiler.cppstd=gnu20"
    CONAN_INSTALL_CMD+=" --build=missing conanfile.py"

    if [[ $ENABLE_PYTHON -eq 1 ]]; then
        CONAN_INSTALL_CMD+=" -o *:with_python_bindings=True"
    fi

    echo "Running Conan install..."
    eval "${CONAN_INSTALL_CMD}"
fi

deactivate

# ---------------------------------------------------------------------------
# CMake
# ---------------------------------------------------------------------------
TOOLCHAIN_FILE="${BUILD_TYPE_DIR}/build/${BUILD_TYPE}/generators/conan_toolchain.cmake"

if [[ ! -f "${TOOLCHAIN_FILE}" ]]; then
    # Fallback: look for toolchain in the output folder directly
    TOOLCHAIN_FILE="${BUILD_TYPE_DIR}/conan_toolchain.cmake"
fi

if [[ -f "${TOOLCHAIN_FILE}" ]]; then
    CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}"
fi

CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_INSTALL_PREFIX=$(pwd)/_run -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=${BUILD_TYPE}"

echo "Running CMake..."
cmake ${CMAKE_FLAGS} -G Ninja -B "${BUILD_TYPE_DIR}" -S "."

# Symlinks for convenience
ln -f -s -n "${BUILD_TYPE_DIR}" "${BUILD_DIR}.current"

echo ""
echo "Build environment is ready at: ${BUILD_TYPE_DIR}"
echo ""
echo "To build:"
echo "  cd ${BUILD_TYPE_DIR} && ninja"
echo ""
echo "To run tests:"
echo "  cd ${BUILD_TYPE_DIR} && ninja tests_fast"
