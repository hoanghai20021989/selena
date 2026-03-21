file(GLOB_RECURSE SRC *.cc *.cpp)
engine_add_test(engine_execution_test_reg SRCS "${SRC}" LIBS engine_execution)
