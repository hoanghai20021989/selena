#pragma once

#include "engine/core/order_adapter.h"
#include "engine/core/types.h"

namespace engine::execution {

// Re-export core order types into the execution namespace
using core::CancelOrderRequest;
using core::InternalOrderId;
using core::NewOrderRequest;
using core::OrdStatus;
using core::OrderUpdate;
using core::TimeInForce;

/// Trigger ID generator — produces unique IDs for order triggers
class TriggerIdGenerator
{
public:
    explicit TriggerIdGenerator(uint32_t publisher_id) : publisher_id_(publisher_id) {}

    core::TriggerId Generate()
    {
        return core::TriggerId{(static_cast<uint64_t>(publisher_id_) << 32) | ++counter_};
    }

private:
    uint32_t publisher_id_{0};
    uint32_t counter_{0};
};

} // namespace engine::execution
