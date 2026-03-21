file(GLOB_RECURSE SRC *.cc *.cpp)
engine_add_test(engine_services_test_reg SRCS "${SRC}" LIBS engine_services)
