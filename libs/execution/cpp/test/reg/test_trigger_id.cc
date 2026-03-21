#include "engine/execution/types.h"

#include <gtest/gtest.h>

namespace engine::execution {

TEST(TriggerIdGeneratorTest, GeneratesUniqueIds)
{
    TriggerIdGenerator gen(1);

    auto id1 = gen.Generate();
    auto id2 = gen.Generate();

    EXPECT_NE(id1, id2);
    EXPECT_TRUE(id1.IsValid());
    EXPECT_TRUE(id2.IsValid());
}

TEST(TriggerIdGeneratorTest, DifferentPublishersProduceDifferentRanges)
{
    TriggerIdGenerator gen1(1);
    TriggerIdGenerator gen2(2);

    auto id1 = gen1.Generate();
    auto id2 = gen2.Generate();

    EXPECT_NE(id1, id2);
}

} // namespace engine::execution
