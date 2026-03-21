#pragma once

#include "engine/core/types.h"

#include <cstdint>
#include <string>

namespace engine::risk {

/// Hierarchical risk reject reason flags
enum class RiskRejectReason : uint64_t
{
    kNone = 0,
    kOrderRateBreach = 1 << 0,
    kPositionLimitBreach = 1 << 1,
    kPriceLimitBreach = 1 << 2,
    kFatFingerBreach = 1 << 3,
    kPendingOrderLimitBreach = 1 << 4,
};

inline RiskRejectReason operator|(RiskRejectReason a, RiskRejectReason b)
{
    return static_cast<RiskRejectReason>(static_cast<uint64_t>(a) | static_cast<uint64_t>(b));
}

inline bool HasFlag(RiskRejectReason flags, RiskRejectReason flag)
{
    return (static_cast<uint64_t>(flags) & static_cast<uint64_t>(flag)) != 0;
}

struct RiskReject
{
    RiskRejectReason reason{RiskRejectReason::kNone};
    std::string details;
};

template <typename T = void>
struct RiskCheckResult
{
    bool passed{true};
    RiskReject reject{};

    static RiskCheckResult Pass() { return {true, {}}; }
    static RiskCheckResult Fail(RiskRejectReason reason, std::string details = "")
    {
        return {false, {reason, std::move(details)}};
    }

    explicit operator bool() const { return passed; }
};

} // namespace engine::risk
