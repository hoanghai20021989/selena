#include "engine/core/log_macros.h"
#include "engine/core/security_master.h"
#include "engine/core/types.h"
#include "engine/engine/engine_config.h"

#include <iostream>
#include <string>

int main(int argc, char* argv[])
{
    std::string exchange = "binance";
    std::string symbol = "BTCUSDT";

    for (int i = 1; i < argc; ++i)
    {
        std::string arg = argv[i];
        if ((arg == "-e" || arg == "--exchange") && i + 1 < argc)
        {
            exchange = argv[++i];
        }
        else if ((arg == "-s" || arg == "--symbol") && i + 1 < argc)
        {
            symbol = argv[++i];
        }
        else if (arg == "-h" || arg == "--help")
        {
            std::cout << "Usage: trader [options]\n"
                      << "  -e, --exchange  Exchange name [default: binance]\n"
                      << "  -s, --symbol    Symbol to trade [default: BTCUSDT]\n"
                      << "  -h, --help      Show help\n";
            return 0;
        }
    }

    // Initialize security master
    engine::core::SecurityMaster security_master;
    auto inst_idx = security_master.AddInstrument(symbol, exchange, 2, 0.001, 100.0, "crypto");

    ENGINE_LOG_INF("MAIN", "Starting trading engine for {} on {}", symbol, exchange);
    ENGINE_LOG_INF("MAIN", "Instrument index: {}", inst_idx.value);

    // Engine would be configured here with concrete adapters:
    //
    // engine::engine::EngineConfig config{
    //     .market_data = std::make_unique<BinanceMarketDataAdapter>(ws_url),
    //     .orders = std::make_unique<BinanceOrderAdapter>(api_key, secret),
    //     .time_provider = std::make_unique<engine::core::RealTimeProvider>(),
    // };

    ENGINE_LOG_INF("MAIN", "Engine ready. Implement concrete adapters to connect to {}", exchange);

    return 0;
}
