file(GLOB_RECURSE SRC *.cc *.cpp)
engine_add_test(engine_core_test_reg SRCS "${SRC}" LIBS engine_core)
