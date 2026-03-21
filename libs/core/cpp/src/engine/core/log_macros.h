#pragma once

#include <spdlog/spdlog.h>
#include <fmt/format.h>

// ---------------------------------------------------------------------------
// Logging macros — backed by spdlog (public replacement for quill/gng::log)
// ---------------------------------------------------------------------------

#define ENGINE_LOG_DBG(label, ...) SPDLOG_DEBUG("[{}] {}", label, fmt::format(__VA_ARGS__))
#define ENGINE_LOG_INF(label, ...) SPDLOG_INFO("[{}] {}", label, fmt::format(__VA_ARGS__))
#define ENGINE_LOG_WRN(label, ...) SPDLOG_WARN("[{}] {}", label, fmt::format(__VA_ARGS__))
#define ENGINE_LOG_ERR(label, ...) SPDLOG_ERROR("[{}] {}", label, fmt::format(__VA_ARGS__))

// NV helper — format as name[value] for structured logging
#define NV(name, val) fmt::format("{}[{}]", name, val)
