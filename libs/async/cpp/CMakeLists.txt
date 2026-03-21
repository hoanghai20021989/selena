set(TARGET engine_async)

file(GLOB_RECURSE SOURCES src/*.cc src/*.cpp)
add_library(${TARGET} STATIC ${SOURCES})

target_include_directories(${TARGET} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(${TARGET} PUBLIC
    engine_core
    Threads::Threads
)

if(ENABLE_CPP_TEST)
    add_subdirectory(test)
endif()
