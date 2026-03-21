#pragma once

#include "engine/async/types.h"

#include <tuple>
#include <variant>

namespace engine::async {

/// EventRelayBaseT — base class for event-driven strategy cores.
/// Mirrors the hyrule pattern: Core processes input events, emits output events.
///
/// @tparam Core        The concrete strategy/processor type (CRTP)
/// @tparam InTuple     std::tuple of input event types
/// @tparam OutTuple    std::tuple of output event types
/// @tparam StreamTag   SingleStreamTag or MultiHashedStreamTag
template <typename Core, typename InTuple, typename OutTuple, typename StreamTag = SingleStreamTag>
class EventRelayBaseT
{
public:
    using InputEventTuple = InTuple;
    using OutputEventTuple = OutTuple;

    // Convert tuple to variant for generic dispatch
    template <typename Tuple>
    struct TupleToVariant;

    template <typename... Ts>
    struct TupleToVariant<std::tuple<Ts...>>
    {
        using type = std::variant<Ts...>;
    };

    using InputEventVariant = typename TupleToVariant<InTuple>::type;
    using OutputEventVariant = typename TupleToVariant<OutTuple>::type;

protected:
    /// Emit an output event (to be wired by the engine layer)
    template <typename Event>
    void Emit(Event&& evt)
    {
        // Default: no-op. Engine layer wires this to downstream consumers.
        (void)evt;
    }
};

/// Macro to pull in relay template types into a concrete core
#define ENGINE_RELAY_TEMPLATE_TYPES(BaseRelay)                                   \
    using InputEventTuple = typename BaseRelay::InputEventTuple;                 \
    using OutputEventTuple = typename BaseRelay::OutputEventTuple;               \
    using InputEventVariant = typename BaseRelay::InputEventVariant;             \
    using OutputEventVariant = typename BaseRelay::OutputEventVariant;

} // namespace engine::async
