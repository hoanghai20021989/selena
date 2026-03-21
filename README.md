# Selena

A C++23 low-latency trading engine.

## Overview

Selena is a modular trading engine designed for low-latency execution across multiple exchanges. It provides normalized market data ingestion, order management, risk checks, and a strategy framework built on an event-driven architecture.

### Key Design Principles

- **Strong type safety** — Zero-cost index types (`InstrumentIndex`, `SecurityIndex`, `InternalOrderId`) prevent accidental misuse at compile time.
- **Event-driven cores** — Strategies are CRTP-based event relays with statically-dispatched input/output event variants.
- **Dependency injection** — Adapters for market data, orders, and time are abstract interfaces, making the engine testable and exchange-agnostic.
- **Modular libraries** — Each concern (core types, execution, risk, strategy) is a separate static library with its own tests.

## Architecture

```
apps/trader          Main trading application
libs/
  core               Types, adapters (market data, order), security master, time provider, protobuf
  async              Event relay framework (CRTP-based event processing)
  execution          Order execution layer, trigger ID generation
  services           Timer events, position tracking, alerts
  risk               Pre-trade risk checks with composable rejection reasons
  strategy           Strategy framework and relay base definitions
  engine             Top-level engine config (dependency injection container)
```

### Data Flow

```
Market Data Feed ──▶ IMarketDataAdapter ──▶ BookSnapshot / TradeEvent
                                                │
                                     Strategy (EventRelay)
                                                │
                                      NewOrderRequest / CancelOrderRequest
                                                │
                           IOrderAdapter ──▶ Exchange ──▶ OrderUpdate
```

## Building

### Prerequisites

- Clang (C++23 support)
- CMake 3.25+
- Ninja
- Python 3 (for Conan)

### Setup

```bash
# First-time setup — installs dependencies via Conan, configures CMake
./configure.sh

# Build
cd _build/clang_Debug && ninja

# Run tests
cd _build/clang_Debug && ninja tests_fast

# Run a specific test
./_build/clang_Debug/tests/engine_core_test_reg.out
```

### Build Variants

```bash
./configure.sh --release          # Release build
./configure.sh --asan             # Address Sanitizer
./configure.sh --tsan             # Thread Sanitizer
./configure.sh --skip-conan       # Skip dependency resolution
./configure.sh --wipe             # Clean rebuild
```

## Dependencies

Managed via [Conan 2](https://conan.io/):

| Dependency | Purpose |
|---|---|
| fmt | String formatting |
| spdlog | Structured logging |
| abseil | Strings, time, containers |
| protobuf | Configuration serialization |
| rapidjson | JSON parsing |
| tsl-robin-map | Fast hash maps |
| gtest | Unit testing |
| benchmark | Performance benchmarks |

## CI

Local CI runs on a GitHub Actions self-hosted runner in a container.

```bash
# One-time setup (get token from GitHub repo settings > Actions > Runners)
./devtools/ci/setup-runner.sh <RUNNER_TOKEN>
```

CI triggers on push to `main` and on pull requests. See [CLAUDE.md](CLAUDE.md) for details.

## License

Proprietary. All rights reserved.
