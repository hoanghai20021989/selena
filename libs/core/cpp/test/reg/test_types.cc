#include "engine/core/types.h"
#include "engine/core/fixed_vector.h"
#include "engine/core/security_master.h"

#include <gtest/gtest.h>

namespace engine::core {

TEST(TypesTest, SidedAccess)
{
    SidedPx px;
    px[Side::kBid] = Px{100.0};
    px[Side::kAsk] = Px{101.0};

    EXPECT_EQ(px[Side::kBid].value, 100.0);
    EXPECT_EQ(px[Side::kAsk].value, 101.0);
}

TEST(TypesTest, StrongIndexComparison)
{
    InstrumentIndex a{1};
    InstrumentIndex b{2};
    InstrumentIndex c{1};

    EXPECT_NE(a, b);
    EXPECT_EQ(a, c);
    EXPECT_TRUE(a < b);
}

TEST(TypesTest, StrongIndexInvalid)
{
    auto invalid = InstrumentIndex::Invalid();
    EXPECT_FALSE(invalid.IsValid());

    InstrumentIndex valid{0};
    EXPECT_TRUE(valid.IsValid());
}

TEST(TypesTest, PxArithmetic)
{
    Px a{10.0};
    Px b{3.0};

    EXPECT_EQ((a + b).value, 13.0);
    EXPECT_EQ((a - b).value, 7.0);
    EXPECT_EQ((a * 2.0).value, 20.0);
}

TEST(TypesTest, ResultType)
{
    auto ok = Result<>::Success();
    EXPECT_TRUE(ok);

    auto err = Result<>::Error("something failed");
    EXPECT_FALSE(err);
    EXPECT_EQ(err.error_msg, "something failed");
}

TEST(FixedVectorTest, BasicUsage)
{
    fixed_vector<int> v;
    v.reserve(4);

    v.emplace_back(10);
    v.emplace_back(20);
    v.emplace_back(30);

    EXPECT_EQ(v.size(), 3u);
    EXPECT_EQ(v[0], 10);
    EXPECT_EQ(v[1], 20);
    EXPECT_EQ(v[2], 30);

    v.pop_back();
    EXPECT_EQ(v.size(), 2u);
}

TEST(FixedVectorTest, ThrowsOnOverflow)
{
    fixed_vector<int> v;
    v.reserve(1);
    v.emplace_back(1);
    EXPECT_THROW(v.emplace_back(2), std::length_error);
}

TEST(SecurityMasterTest, AddAndFind)
{
    SecurityMaster sm;

    auto idx = sm.AddInstrument("BTCUSDT", "binance", 2, 0.001, 100.0, "crypto");
    EXPECT_EQ(idx.value, 0);

    auto found = sm.FindInstrument("BTCUSDT");
    EXPECT_TRUE(found.has_value());
    EXPECT_EQ(found->value, 0);

    auto& record = sm.GetInstrument(idx);
    EXPECT_EQ(record.symbol, "BTCUSDT");
    EXPECT_EQ(record.exchange, "binance");
    EXPECT_EQ(record.asset_class, "crypto");
}

TEST(SecurityMasterTest, SecurityIndex)
{
    SecurityMaster sm;

    auto sec1 = sm.AddSecurity("BTCUSDT", "binance");
    auto sec2 = sm.AddSecurity("BTCUSDT", "okx");
    auto sec3 = sm.AddSecurity("BTCUSDT", "binance"); // duplicate

    EXPECT_EQ(sec1.value, 0);
    EXPECT_EQ(sec2.value, 1);
    EXPECT_EQ(sec3, sec1); // same key returns same index
}

} // namespace engine::core
