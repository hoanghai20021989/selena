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
- **Versioning** follows [Semantic Versioning](https://semver.org/) (MAJOR.MINOR.PATCH). Version is extracted from git tags via `cmake/modules/Versioning.cmake`.

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

## CI/CD

Local CI uses a GitHub Actions self-hosted runner on `100.85.32.4` (accessible via SSH) running in a Docker container.

```bash
# One-time setup:
# 1. Get a runner token from https://github.com/hoanghai20021989/selena/settings/actions/runners/new
# 2. Build image and start runner:
./devtools/ci/setup-runner.sh <RUNNER_TOKEN>
```

CI triggers on push to `main` and on pull requests. The workflow (`.github/workflows/ci.yml`) runs configure, build, and test. Branch protection requires CI to pass before merging. PRs auto-merge (squash) when CI passes.

### Runner Management

The runner lives on `100.85.32.4` as a Docker container named `selena-runner`.

```bash
# Check runner status
ssh 100.85.32.4 "docker logs --tail 10 selena-runner"

# Simple restart (if runner is just stopped/hung)
ssh 100.85.32.4 "docker restart selena-runner"

# Full re-register (if config is corrupted or runner won't start)
# 1. Get a fresh token:
gh api -X POST repos/hoanghai20021989/selena/actions/runners/registration-token --jq '.token'
# 2. Remove old container and config volume:
ssh 100.85.32.4 "docker rm -f selena-runner && docker volume rm selena-runner-config"
# 3. Start with new token:
ssh 100.85.32.4 "docker run -d --name selena-runner --restart unless-stopped \
    -v selena-runner-config:/opt/actions-runner \
    -v selena-ccache:/home/runner/.cache/ccache \
    -v selena-conan:/home/runner/.conan2 \
    --entrypoint /bin/bash selena-ci \
    -c 'cd /opt/actions-runner && ./config.sh --url https://github.com/hoanghai20021989/selena --token <TOKEN> --name selena-local --labels self-hosted,linux --unattended --replace && ./run.sh'"
```

### Gitea (Self-hosted Git + CI)

Gitea runs on `100.85.32.4` as a Docker Compose stack alongside the CI runner.

```bash
# Web UI: http://100.85.32.4:3000 (login: selena/selena)
# Git SSH: ssh://git@100.85.32.4:2222/selena/selena.git
# Git HTTP: http://100.85.32.4:3000/selena/selena.git

# Setup from scratch:
./devtools/gitea/setup-gitea.sh

# Manage Gitea services:
ssh 100.85.32.4 "cd /tmp/selena-gitea && docker compose logs -f"
ssh 100.85.32.4 "cd /tmp/selena-gitea && docker compose restart"

# Re-register Gitea runner (if runner won't pick up jobs):
ssh 100.85.32.4 'cd /tmp/selena-gitea && docker compose stop runner && docker compose rm -f runner && docker volume rm -f selena-gitea_runner-data'
# Then get a new token from Gitea API and restart:
ssh 100.85.32.4 'RUNNER_TOKEN=$(curl -sf "http://localhost:3000/api/v1/repos/selena/selena/actions/runners/registration-token" -u "selena:selena" | python3 -c "import sys,json; print(json.load(sys.stdin)[\"token\"])") && cd /tmp/selena-gitea && RUNNER_TOKEN=$RUNNER_TOKEN docker compose up -d runner'
```

Gitea Actions uses `.gitea/workflows/ci.yml` (GitHub Actions compatible syntax). The runner executes jobs inside the `selena-ci` Docker image.

### CI Files

- `devtools/ci/Containerfile` — CI container image (Fedora + clang/cmake/ninja/conan/nodejs)
- `devtools/ci/setup-runner.sh` — GitHub Actions self-hosted runner setup
- `devtools/gitea/docker-compose.yml` — Gitea + act_runner services
- `devtools/gitea/setup-gitea.sh` — Gitea one-command setup
- `.github/workflows/ci.yml` — GitHub Actions workflow
- `.gitea/workflows/ci.yml` — Gitea Actions workflow

## Key Files

- `CMakeLists.txt` — Root CMake config
- `conanfile.py` — Conan dependency definitions
- `configure.sh` — One-command project setup
- `cmake/modules/EngineFlags.cmake` — Compiler warnings/flags
- `cmake/modules/SetupTest.cmake` — Test infrastructure (`engine_add_test`, `engine_add_mock`)
- `cmake/modules/SetupProtobuf.cmake` — Protobuf code generation
