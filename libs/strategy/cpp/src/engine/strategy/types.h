#pragma once

#include "engine/async/event_relay.h"
#include "engine/core/order_adapter.h"
#include "engine/core/types.h"
#include "engine/services/types.h"

namespace engine::strategy {

// Placeholder for strategy-specific types.
// Concrete strategies will define their own relay base using:
//
// #define MY_STRATEGY_BASE_RELAY \
//     async::EventRelayBaseT<MyCore, \
//         std::tuple<services::BookSnapshot, services::Timer125msEvent, ...>, \
//         std::tuple<core::NewOrderRequest, ...>, \
//         async::SingleStreamTag>

} // namespace engine::strategy
