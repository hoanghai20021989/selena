#include "engine/async/event_relay.h"
#include "engine/core/types.h"

#include <gtest/gtest.h>

namespace engine::async {

struct TestBookEvent
{
    core::InstrumentIndex instrument;
    double mid_price{0};
};

struct TestOrderRequest
{
    core::InstrumentIndex instrument;
    core::Side side{core::Side::kBuy};
    double price{0};
};

#define TEST_STRATEGY_BASE_RELAY \
    EventRelayBaseT<TestStrategyCore, std::tuple<TestBookEvent>, std::tuple<TestOrderRequest>, SingleStreamTag>

struct TestStrategyCore : public TEST_STRATEGY_BASE_RELAY
{
    using BaseRelay = TEST_STRATEGY_BASE_RELAY;
    ENGINE_RELAY_TEMPLATE_TYPES(BaseRelay)

    int book_events_processed{0};

    void Process(const TestBookEvent& evt)
    {
        ++book_events_processed;
        (void)evt;
    }
};

TEST(EventRelayTest, CoreCanProcessEvents)
{
    TestStrategyCore core;
    TestBookEvent evt{core::InstrumentIndex{0}, 100.5};
    core.Process(evt);
    EXPECT_EQ(core.book_events_processed, 1);
}

TEST(EventRelayTest, VariantTypesDerived)
{
    // Just verify the variant types compile correctly
    using InVar = TestStrategyCore::InputEventVariant;
    using OutVar = TestStrategyCore::OutputEventVariant;

    InVar in_event = TestBookEvent{};
    OutVar out_event = TestOrderRequest{};

    EXPECT_TRUE(std::holds_alternative<TestBookEvent>(in_event));
    EXPECT_TRUE(std::holds_alternative<TestOrderRequest>(out_event));
}

} // namespace engine::async
