#pragma once

#include "engine/core/market_data_adapter.h"
#include "engine/core/types.h"

namespace engine::services {

// Re-export market data types
using core::BookSnapshot;
using core::Level;
using core::MarketStatus;
using core::TradeEvent;

// ---------------------------------------------------------------------------
// Timer events — periodic heartbeats at various intervals
// ---------------------------------------------------------------------------
struct Timer5msEvent
{
    core::SysTime timestamp;
};
struct Timer25msEvent
{
    core::SysTime timestamp;
};
struct Timer125msEvent
{
    core::SysTime timestamp;
};
struct Timer250msEvent
{
    core::SysTime timestamp;
};
struct Timer500msEvent
{
    core::SysTime timestamp;
};
struct Timer1sEvent
{
    core::SysTime timestamp;
};
struct Timer5sEvent
{
    core::SysTime timestamp;
};
struct Timer1mEvent
{
    core::SysTime timestamp;
};

// ---------------------------------------------------------------------------
// Position event
// ---------------------------------------------------------------------------
struct PositionEvent
{
    core::InstrumentIndex instrument;
    core::Qty net_qty{0};
    double avg_price{0};
    double unrealized_pnl{0};
    double realized_pnl{0};
};

// ---------------------------------------------------------------------------
// Alert event
// ---------------------------------------------------------------------------
enum class AlertSeverity : uint8_t
{
    kInfo = 0,
    kWarning,
    kError,
};

struct AlertEvent
{
    std::string source;
    std::string message;
    AlertSeverity severity{AlertSeverity::kInfo};
    core::SysTime timestamp;
};

} // namespace engine::services
