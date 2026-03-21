# Selena - Trading Engine

## Project Overview

Selena is a C++23 low-latency trading engine built with CMake + Conan 2 + Ninja. It uses clang as the primary compiler.

## Architecture

The project follows a modular library structure under `libs/`, with applications under `apps/`:

- **libs/core** — Core types, adapters (market data, order), security master, time provider, logging macros. Has protobuf definitions in `proto/`.
- **libs/async** — Async event relay and event types.
- **libs/execution** — Order execution layer with trigger IDs.
- **libs/services** — Service abstractions.
- **libs/risk** — Risk management.
- **libs/strategy** — Strategy framework.
- **libs/engine** — Top-level engine that ties all libraries together.
- **apps/trader** — Main trading application binary.

Each library follows the pattern: `libs/<name>/cpp/src/engine/<name>/` for sources, `libs/<name>/cpp/test/` for tests.

## Build Commands

```bash
# First-time setup (installs deps via Conan, configures CMake)
./configure.sh

# Build (after configure)
cd _build/clang_Debug && ninja

# Run all tests
cd _build/clang_Debug && ninja tests_fast

# Run a specific test binary
./_build/clang_Debug/tests/<test_name>.out

# Release build
./configure.sh --release
cd _build/clang_Release && ninja

# Reconfigure without re-running Conan
./configure.sh --skip-conan

# Wipe and reconfigure
./configure.sh --wipe

# With sanitizers
./configure.sh --asan   # Address Sanitizer
./configure.sh --tsan   # Thread Sanitizer
```

## Code Conventions

- **C++23** standard, compiled with `-Werror -Wall` and additional strict warnings.
- Header-only types go in `.h` files; translation units in `.cc` files.
- Include paths use the pattern `engine/<library>/<header>.h` (e.g., `#include "engine/core/types.h"`).
- Libraries are static by default; shared only for Python bindings.
- Each library has a CMake target named `engine_<name>` (e.g., `engine_core`, `engine_async`).
- Tests use Google Test. Test targets are created via `engine_add_test()` from `cmake/modules/SetupTest.cmake`.
- Protobuf definitions live under `libs/<name>/proto/src/engine/<name>/`.

## Adding a New Library

1. Create `libs/<name>/CMakeLists.txt` with `add_subdirectory(cpp)`.
2. Create `libs/<name>/cpp/CMakeLists.txt` defining `engine_<name>` target.
3. Add sources under `libs/<name>/cpp/src/engine/<name>/`.
4. Add tests under `libs/<name>/cpp/test/reg/` using `engine_add_test()`.
5. Register in `libs/CMakeLists.txt`.

## Adding a New Test

```cmake
# In libs/<name>/cpp/test/reg/CMakeLists.txt
file(GLOB_RECURSE SRC *.cc *.cpp)
engine_add_test(engine_<name>_test_reg SRCS "${SRC}" LIBS engine_<name>)
```

## Dependencies

Managed via Conan 2 (`conanfile.py`). Key dependencies:
- fmt, spdlog (logging/formatting)
- abseil (strings, time, containers)
- protobuf (serialization)
- rapidjson (JSON parsing)
- tsl-robin-map (fast hash maps)
- gtest, benchmark (testing)

## Key Files

- `CMakeLists.txt` — Root CMake config
- `conanfile.py` — Conan dependency definitions
- `configure.sh` — One-command project setup
- `cmake/modules/EngineFlags.cmake` — Compiler warnings/flags
- `cmake/modules/SetupTest.cmake` — Test infrastructure (`engine_add_test`, `engine_add_mock`)
- `cmake/modules/SetupProtobuf.cmake` — Protobuf code generation
