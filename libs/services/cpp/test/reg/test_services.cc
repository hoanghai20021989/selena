#include "engine/services/types.h"

#include <gtest/gtest.h>

namespace engine::services {

TEST(ServicesTest, PositionEventDefaults)
{
    PositionEvent evt;
    EXPECT_EQ(evt.net_qty, 0);
    EXPECT_EQ(evt.avg_price, 0.0);
}

TEST(ServicesTest, AlertEventConstruction)
{
    AlertEvent alert;
    alert.source = "risk";
    alert.message = "position limit breached";
    alert.severity = AlertSeverity::kError;

    EXPECT_EQ(alert.source, "risk");
    EXPECT_EQ(alert.severity, AlertSeverity::kError);
}

} // namespace engine::services
