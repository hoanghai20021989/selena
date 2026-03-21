set(PROTO_FILES engine/core/core.proto)

# Use protobuf_generate from Conan's protobuf package
add_library(engine_core_pb STATIC)
target_link_libraries(engine_core_pb PUBLIC protobuf::libprotobuf)

protobuf_generate(
    TARGET engine_core_pb
    PROTOS ${PROTO_FILES}
    PROTOC_OUT_DIR ${CMAKE_CURRENT_BINARY_DIR}
    IMPORT_DIRS ${CMAKE_CURRENT_SOURCE_DIR}
)

target_include_directories(engine_core_pb PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
)
