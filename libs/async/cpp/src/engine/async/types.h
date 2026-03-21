#pragma once

#include "engine/core/types.h"

#include <cstdint>
#include <variant>

namespace engine::async {

// ---------------------------------------------------------------------------
// Event identity
// ---------------------------------------------------------------------------
using EventId = uint32_t;

struct EventHeader
{
    EventId id{0};
    core::SysTime timestamp{};
};

// ---------------------------------------------------------------------------
// Security-linked event wrapper — attaches instrument/security index to any event
// ---------------------------------------------------------------------------
template <typename T>
struct SecurityLinkedEvent
{
    core::SecurityIndex security_index;
    core::InstrumentIndex instrument_index;
    T event;
};

// ---------------------------------------------------------------------------
// Stream tags for event relay pattern
// ---------------------------------------------------------------------------
struct SingleStreamTag {};
struct MultiHashedStreamTag {};

} // namespace engine::async
