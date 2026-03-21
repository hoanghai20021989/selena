set(TARGET engine_engine)

file(GLOB_RECURSE SOURCES src/*.cc src/*.cpp)
add_library(${TARGET} STATIC ${SOURCES})

target_include_directories(${TARGET} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(${TARGET} PUBLIC
    engine_core
    engine_async
    engine_execution
    engine_services
    engine_risk
    engine_strategy
)
