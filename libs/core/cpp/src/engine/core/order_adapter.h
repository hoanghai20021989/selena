#pragma once

#include "engine/core/types.h"

#include <functional>
#include <string>

namespace engine::core {

// ---------------------------------------------------------------------------
// Time in force
// ---------------------------------------------------------------------------
enum class TimeInForce : uint8_t
{
    kGTC = 0,  // Good-til-canceled
    kIOC,      // Immediate-or-cancel
    kFOK,      // Fill-or-kill
    kGTD,      // Good-til-date
};

// ---------------------------------------------------------------------------
// Order status
// ---------------------------------------------------------------------------
enum class OrdStatus : uint8_t
{
    kPendingNew = 0,
    kNew,
    kPartiallyFilled,
    kFilled,
    kPendingCancel,
    kCanceled,
    kRejected,
    kExpired,
};

// ---------------------------------------------------------------------------
// New order request
// ---------------------------------------------------------------------------
struct NewOrderRequest
{
    InternalOrderId internal_id;
    InstrumentIndex instrument;
    Side side{Side::kBuy};
    Px limit_price;
    Qty quantity{0};
    TimeInForce tif{TimeInForce::kGTC};
    std::string client_order_id;
};

// ---------------------------------------------------------------------------
// Cancel request
// ---------------------------------------------------------------------------
struct CancelOrderRequest
{
    InternalOrderId internal_id;
    std::string client_order_id;
};

// ---------------------------------------------------------------------------
// Order update (ack, fill, cancel, reject)
// ---------------------------------------------------------------------------
struct OrderUpdate
{
    InternalOrderId internal_id;
    InstrumentIndex instrument;
    OrdStatus status{OrdStatus::kPendingNew};
    Side side{Side::kBuy};
    Px limit_price;
    Qty original_qty{0};
    Qty filled_qty{0};
    Qty remaining_qty{0};
    Px last_fill_price;
    Qty last_fill_qty{0};
    std::string client_order_id;
    std::string exchange_order_id;
    std::string reject_reason;

    bool IsDone() const
    {
        return status == OrdStatus::kFilled || status == OrdStatus::kCanceled || status == OrdStatus::kRejected ||
               status == OrdStatus::kExpired;
    }
};

// ---------------------------------------------------------------------------
// Abstract order adapter — implement per exchange/provider.
// ---------------------------------------------------------------------------
struct IOrderAdapter
{
    virtual ~IOrderAdapter() = default;

    virtual void SendNewOrder(const NewOrderRequest& req) = 0;
    virtual void SendCancel(const CancelOrderRequest& req) = 0;

    using OrderUpdateCallback = std::function<void(const OrderUpdate&)>;
    virtual void SetOrderUpdateCallback(OrderUpdateCallback cb) = 0;

    virtual void Start() = 0;
    virtual void Stop() = 0;
};

} // namespace engine::core
