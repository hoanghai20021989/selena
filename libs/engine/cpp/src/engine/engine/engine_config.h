#pragma once

#include "engine/core/market_data_adapter.h"
#include "engine/core/order_adapter.h"
#include "engine/core/time_provider.h"

#include <memory>

namespace engine::engine {

/// Engine configuration — dependency-injected adapters.
/// Swap adapters to switch between exchanges/providers without touching strategy code.
struct EngineConfig
{
    std::unique_ptr<core::IMarketDataAdapter> market_data;
    std::unique_ptr<core::IOrderAdapter> orders;
    std::unique_ptr<core::ITimeProvider> time_provider;
};

} // namespace engine::engine
