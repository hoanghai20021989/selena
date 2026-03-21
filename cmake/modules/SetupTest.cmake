enable_testing()

include(GoogleTest)

set(TEST_DIR "${CMAKE_BINARY_DIR}/tests")
make_directory(${TEST_DIR})

# Custom target: run all tests (excluding valgrind)
add_custom_target(tests
    COMMAND ctest -E '.*_memchecked_.*' --output-on-failure --schedule-random --timeout 1200 -j $\{NPROC\}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    COMMENT "Running all tests..."
    USES_TERMINAL
)

# Fast tests (same as tests for now, no valgrind)
add_custom_target(tests_fast
    COMMAND ctest -E '.*_memchecked_.*' --output-on-failure --schedule-random --timeout 1200 -j $\{NPROC\}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    COMMENT "Running fast tests..."
    USES_TERMINAL
)

# Valgrind memcheck tests
add_custom_target(tests_memcheck
    COMMAND ctest -R '.*_memchecked_.*' --output-on-failure --schedule-random --timeout 1200 -j $\{NPROC\}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    COMMENT "Running memory-checked tests..."
    USES_TERMINAL
)

# ---------------------------------------------------------------------------
# engine_add_test — create a GTest executable + register with ctest
# Usage: engine_add_test(test_name SRCS src1.cc src2.cc LIBS lib1 lib2)
# ---------------------------------------------------------------------------
function(engine_add_test)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs SRCS LIBS)

    cmake_parse_arguments(PARSE_ARGV 1 arg
        "${options}" "${oneValueArgs}" "${multiValueArgs}")

    set(TARGET "${ARGV0}.out")
    add_executable(${TARGET} ${arg_SRCS})

    target_link_libraries(${TARGET}
        GTest::gtest
        GTest::gtest_main
        ${arg_LIBS}
    )

    target_include_directories(${TARGET} PRIVATE ${CMAKE_SOURCE_DIR})

    target_compile_definitions(${TARGET} PRIVATE
        TEST_DATA_DIR=${CMAKE_SOURCE_DIR}/test
    )

    set_target_properties(${TARGET} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${TEST_DIR}"
    )

    gtest_discover_tests(${TARGET}
        WORKING_DIRECTORY ${TEST_DIR}
        PROPERTIES TIMEOUT 600
        XML_OUTPUT_DIR ${TEST_DIR}/xml
    )

    # Valgrind companion test
    add_test(NAME ${ARGV0}_memchecked_test
        COMMAND valgrind
        --error-exitcode=1
        --tool=memcheck
        --leak-check=full
        --errors-for-leak-kinds=definite
        --show-leak-kinds=definite
        $<TARGET_FILE:${TARGET}>
        WORKING_DIRECTORY ${TEST_DIR}
    )
    set_tests_properties(${ARGV0}_memchecked_test PROPERTIES TIMEOUT 1200)

    add_dependencies(tests ${TARGET})
    add_dependencies(tests_fast ${TARGET})
    add_dependencies(tests_memcheck ${TARGET})
endfunction()

# ---------------------------------------------------------------------------
# engine_add_mock — create a mock/test-util library
# Usage: engine_add_mock(mock_name SRCS src1.cc LIBS lib1)
# ---------------------------------------------------------------------------
function(engine_add_mock)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs SRCS LIBS)

    cmake_parse_arguments(PARSE_ARGV 1 arg
        "${options}" "${oneValueArgs}" "${multiValueArgs}")

    set(TARGET "${ARGV0}")
    add_library(${TARGET} ${arg_SRCS})

    target_link_libraries(${TARGET}
        GTest::gtest
        GTest::gmock
        ${arg_LIBS}
    )
    target_include_directories(${TARGET} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
endfunction()
