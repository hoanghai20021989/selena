#pragma once

#include "engine/core/types.h"

#include <functional>
#include <string_view>

namespace engine::core {

/// Normalized book level
struct Level
{
    Px price;
    Qty qty{0};
    int32_t num_orders{0};
};

/// Normalized top-of-book snapshot (provider-agnostic)
struct BookSnapshot
{
    InstrumentIndex instrument;
    SysTime exchange_time{};
    SysTime local_time{};

    SidedPx best_px;
    SidedQty best_qty;

    static constexpr size_t kMaxDepth = 10;
    Sided<std::array<Level, kMaxDepth>> levels;
    uint8_t depth{0};
};

/// Normalized trade event
struct TradeEvent
{
    InstrumentIndex instrument;
    SysTime exchange_time{};
    Px price;
    Qty qty{0};
    Side aggressor_side{Side::kBuy};
};

/// Market status for an instrument
enum class MarketStatus : uint8_t
{
    kUnknown = 0,
    kPreOpen,
    kOpen,
    kHalted,
    kClosed,
};

/// Abstract market data adapter — implement per exchange/provider.
struct IMarketDataAdapter
{
    virtual ~IMarketDataAdapter() = default;

    virtual void Subscribe(InstrumentIndex idx, std::string_view symbol, std::string_view exchange) = 0;
    virtual void Unsubscribe(InstrumentIndex idx) = 0;

    using BookCallback = std::function<void(const BookSnapshot&)>;
    using TradeCallback = std::function<void(const TradeEvent&)>;
    using StatusCallback = std::function<void(InstrumentIndex, MarketStatus)>;

    virtual void SetBookCallback(BookCallback cb) = 0;
    virtual void SetTradeCallback(TradeCallback cb) = 0;
    virtual void SetStatusCallback(StatusCallback cb) = 0;

    virtual void Start() = 0;
    virtual void Stop() = 0;
};

} // namespace engine::core
