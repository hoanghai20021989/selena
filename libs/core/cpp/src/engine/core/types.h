#pragma once

#include <chrono>
#include <cstdint>
#include <compare>
#include <functional>
#include <limits>
#include <type_traits>

namespace engine::core {

// ---------------------------------------------------------------------------
// Time types — std::chrono based, no external dependency
// ---------------------------------------------------------------------------
using SysClock = std::chrono::system_clock;
using SysTime = std::chrono::time_point<SysClock>;
using SteadyClock = std::chrono::steady_clock;
using SteadyTime = std::chrono::time_point<SteadyClock>;
using Duration = std::chrono::nanoseconds;
using RawTime = uint64_t;

// ---------------------------------------------------------------------------
// Strong index — zero-cost typed wrapper for integer IDs
// ---------------------------------------------------------------------------
template <typename T, typename Tag>
struct StrongIndex
{
    using underlying_type = T;

    T value{};

    constexpr StrongIndex() = default;
    constexpr explicit StrongIndex(T v) : value(v) {}

    constexpr auto operator<=>(const StrongIndex&) const = default;
    constexpr bool operator==(const StrongIndex&) const = default;

    constexpr explicit operator T() const { return value; }

    static constexpr StrongIndex Invalid()
    {
        return StrongIndex{std::numeric_limits<T>::max()};
    }

    constexpr bool IsValid() const { return value != std::numeric_limits<T>::max(); }
};

// ---------------------------------------------------------------------------
// Core identity types
// ---------------------------------------------------------------------------
struct InstrumentIndexTag {};
struct SecurityIndexTag {};
struct InternalOrderIdTag {};
struct TriggerIdTag {};

using InstrumentIndex = StrongIndex<uint16_t, InstrumentIndexTag>;
using SecurityIndex = StrongIndex<uint16_t, SecurityIndexTag>;
using InternalOrderId = StrongIndex<uint64_t, InternalOrderIdTag>;
using TriggerId = StrongIndex<uint64_t, TriggerIdTag>;

// ---------------------------------------------------------------------------
// Side
// ---------------------------------------------------------------------------
enum class Side : uint8_t
{
    kBid = 0,
    kAsk = 1,
    kBuy = 0,
    kSell = 1,
};

constexpr Side OtherSide(Side s)
{
    return s == Side::kBid ? Side::kAsk : Side::kBid;
}

// ---------------------------------------------------------------------------
// Price — thin double wrapper with comparison
// ---------------------------------------------------------------------------
struct Px
{
    double value{};

    constexpr Px() = default;
    constexpr explicit Px(double v) : value(v) {}

    constexpr auto operator<=>(const Px&) const = default;
    constexpr bool operator==(const Px&) const = default;

    constexpr Px operator+(Px rhs) const { return Px{value + rhs.value}; }
    constexpr Px operator-(Px rhs) const { return Px{value - rhs.value}; }
    constexpr Px operator*(double rhs) const { return Px{value * rhs}; }
    constexpr Px operator/(double rhs) const { return Px{value / rhs}; }

    constexpr explicit operator double() const { return value; }

    static constexpr Px Invalid() { return Px{std::numeric_limits<double>::quiet_NaN()}; }
};

// ---------------------------------------------------------------------------
// Quantity types
// ---------------------------------------------------------------------------
using Qty = int64_t;
using Qty64 = int64_t;
using Qty32 = int32_t;

// ---------------------------------------------------------------------------
// Notional wrappers
// ---------------------------------------------------------------------------
template <typename T>
struct Notional
{
    T value{};
    constexpr Notional() = default;
    constexpr explicit Notional(T v) : value(v) {}
    constexpr auto operator<=>(const Notional&) const = default;
};

using FloatNotional = Notional<float>;
using DoubleNotional = Notional<double>;
using Int64Notional = Notional<int64_t>;

// ---------------------------------------------------------------------------
// Sided<T> — holds a bid and ask value
// ---------------------------------------------------------------------------
template <typename T>
struct Sided
{
    T bid{};
    T ask{};

    constexpr T& operator[](Side s) { return s == Side::kBid ? bid : ask; }
    constexpr const T& operator[](Side s) const { return s == Side::kBid ? bid : ask; }
};

using SidedPx = Sided<Px>;
using SidedQty = Sided<Qty>;
using SidedQty32 = Sided<Qty32>;
using SidedBool = Sided<bool>;
using SidedFloat = Sided<float>;
using SidedDouble = Sided<double>;

// ---------------------------------------------------------------------------
// Ranged<T> — holds low/high bounds
// ---------------------------------------------------------------------------
template <typename T>
struct Ranged
{
    T low{};
    T high{};
};

using RangedPx = Ranged<Px>;
using RangedQty = Ranged<Qty>;
using RangedFloat = Ranged<float>;

// ---------------------------------------------------------------------------
// Result type (simple error handling)
// ---------------------------------------------------------------------------
template <typename T = void>
struct Result
{
    bool ok{true};
    std::string error_msg{};

    static Result Success() { return Result{true, {}}; }
    static Result Error(std::string msg) { return Result{false, std::move(msg)}; }

    explicit operator bool() const { return ok; }
};

} // namespace engine::core

// Hash specializations for strong index types
template <typename T, typename Tag>
struct std::hash<engine::core::StrongIndex<T, Tag>>
{
    size_t operator()(const engine::core::StrongIndex<T, Tag>& idx) const noexcept
    {
        return std::hash<T>{}(idx.value);
    }
};
