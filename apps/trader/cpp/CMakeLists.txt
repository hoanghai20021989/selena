add_executable(trader src/main.cc)

target_link_libraries(trader
    engine_engine
)

install(TARGETS trader DESTINATION bin)
