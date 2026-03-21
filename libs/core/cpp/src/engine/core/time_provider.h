#pragma once

#include "engine/core/types.h"

namespace engine::core {

/// Abstract time provider — enables deterministic testing
struct ITimeProvider
{
    virtual ~ITimeProvider() = default;
    virtual SysTime Now() const = 0;
    virtual SteadyTime SteadyNow() const = 0;
};

/// Real-time clock implementation
struct RealTimeProvider : ITimeProvider
{
    SysTime Now() const override { return SysClock::now(); }
    SteadyTime SteadyNow() const override { return SteadyClock::now(); }
};

} // namespace engine::core
