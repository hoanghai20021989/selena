file(GLOB_RECURSE SRC *.cc *.cpp)
engine_add_test(engine_async_test_reg SRCS "${SRC}" LIBS engine_async)
