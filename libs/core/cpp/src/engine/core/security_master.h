#pragma once

#include "engine/core/types.h"

#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace engine::core {

/// Per-instrument record
struct InstrumentRecord
{
    InstrumentIndex index;
    std::string symbol;
    std::string exchange;
    int32_t tick_size_decimals{0};
    double min_order_size{0};
    double max_order_size{0};
    std::string asset_class;
};

/// Per-security (symbol x exchange) record
struct SecurityRecord
{
    SecurityIndex index;
    InstrumentIndex instrument_index;
    std::string symbol;
    std::string exchange;
};

/// SecurityMaster — maps symbols/exchanges to typed indices.
/// Two index spaces: InstrumentIndex (exchange-agnostic) and SecurityIndex (exchange-specific).
class SecurityMaster
{
public:
    InstrumentIndex AddInstrument(const std::string& symbol, const std::string& exchange,
                                  int32_t tick_decimals = 0, double min_qty = 0, double max_qty = 0,
                                  const std::string& asset_class = "")
    {
        auto it = symbol_to_instrument_.find(symbol);
        if (it != symbol_to_instrument_.end())
        {
            return it->second;
        }

        InstrumentIndex idx{static_cast<uint16_t>(instruments_.size())};
        instruments_.push_back({idx, symbol, exchange, tick_decimals, min_qty, max_qty, asset_class});
        symbol_to_instrument_[symbol] = idx;
        return idx;
    }

    SecurityIndex AddSecurity(const std::string& symbol, const std::string& exchange)
    {
        std::string key = symbol + "@" + exchange;
        auto it = key_to_security_.find(key);
        if (it != key_to_security_.end())
        {
            return it->second;
        }

        // Ensure instrument exists
        auto inst_idx = AddInstrument(symbol, exchange);

        SecurityIndex idx{static_cast<uint16_t>(securities_.size())};
        securities_.push_back({idx, inst_idx, symbol, exchange});
        key_to_security_[key] = idx;
        return idx;
    }

    const InstrumentRecord& GetInstrument(InstrumentIndex idx) const { return instruments_.at(idx.value); }
    const SecurityRecord& GetSecurity(SecurityIndex idx) const { return securities_.at(idx.value); }

    std::optional<InstrumentIndex> FindInstrument(std::string_view symbol) const
    {
        auto it = symbol_to_instrument_.find(std::string(symbol));
        if (it != symbol_to_instrument_.end())
        {
            return it->second;
        }
        return std::nullopt;
    }

    size_t InstrumentCount() const { return instruments_.size(); }
    size_t SecurityCount() const { return securities_.size(); }

private:
    std::vector<InstrumentRecord> instruments_;
    std::vector<SecurityRecord> securities_;
    std::unordered_map<std::string, InstrumentIndex> symbol_to_instrument_;
    std::unordered_map<std::string, SecurityIndex> key_to_security_;
};

/// Per-instrument data array, indexed by InstrumentIndex
template <typename T>
class DataByInstrument
{
public:
    void Resize(size_t n) { data_.resize(n); }

    T& operator[](InstrumentIndex idx) { return data_[idx.value]; }
    const T& operator[](InstrumentIndex idx) const { return data_[idx.value]; }

    size_t size() const { return data_.size(); }

private:
    std::vector<T> data_;
};

/// Per-security data array, indexed by SecurityIndex
template <typename T>
class DataBySecurity
{
public:
    void Resize(size_t n) { data_.resize(n); }

    T& operator[](SecurityIndex idx) { return data_[idx.value]; }
    const T& operator[](SecurityIndex idx) const { return data_[idx.value]; }

    size_t size() const { return data_.size(); }

private:
    std::vector<T> data_;
};

} // namespace engine::core
