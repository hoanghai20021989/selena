# Global registry for proto include directories
set_property(GLOBAL PROPERTY PROTO_INCLUDE_DIRS)

# Register proto files for global imports
function(register_proto_files)
    cmake_parse_arguments(PROTO "" "PROTO_ROOT" "PROTOS" ${ARGN})

    if(NOT PROTO_PROTOS)
        return()
    endif()

    get_property(current_dirs GLOBAL PROPERTY PROTO_INCLUDE_DIRS)

    if(PROTO_PROTO_ROOT)
        get_filename_component(abs_root ${PROTO_PROTO_ROOT} ABSOLUTE)
        if(EXISTS ${abs_root} AND NOT ${abs_root} IN_LIST current_dirs)
            list(APPEND current_dirs ${abs_root})
        endif()
    endif()

    foreach(proto_file ${PROTO_PROTOS})
        get_filename_component(abs_file ${proto_file} ABSOLUTE)
        get_filename_component(abs_dir ${abs_file} DIRECTORY)
        if(NOT ${abs_dir} IN_LIST current_dirs)
            list(APPEND current_dirs ${abs_dir})
        endif()
    endforeach()

    set_property(GLOBAL PROPERTY PROTO_INCLUDE_DIRS ${current_dirs})
endfunction()

# Prepare include paths for protoc
function(protoc_prepare_include_paths INCLUDE_DIR_ARGS PROTO_ROOT)
    get_property(global_dirs GLOBAL PROPERTY PROTO_INCLUDE_DIRS)

    set(INCLUDE_DIRS)

    if(PROTO_ROOT AND EXISTS ${PROTO_ROOT})
        get_filename_component(abs_root ${PROTO_ROOT} ABSOLUTE)
        list(APPEND INCLUDE_DIRS ${abs_root})
    endif()

    foreach(global_dir ${global_dirs})
        if(EXISTS ${global_dir} AND NOT ${global_dir} IN_LIST INCLUDE_DIRS)
            list(APPEND INCLUDE_DIRS ${global_dir})
        endif()
    endforeach()

    foreach(proto_file ${ARGN})
        get_filename_component(abs_file ${proto_file} ABSOLUTE)
        get_filename_component(abs_path ${abs_file} DIRECTORY)
        if(NOT ${abs_path} IN_LIST INCLUDE_DIRS)
            list(APPEND INCLUDE_DIRS ${abs_path})
        endif()
    endforeach()

    if(Protobuf_INCLUDE_DIR AND EXISTS ${Protobuf_INCLUDE_DIR})
        if(NOT ${Protobuf_INCLUDE_DIR} IN_LIST INCLUDE_DIRS)
            list(APPEND INCLUDE_DIRS ${Protobuf_INCLUDE_DIR})
        endif()
    endif()

    list(REMOVE_DUPLICATES INCLUDE_DIRS)

    set(include_args)
    foreach(include_dir ${INCLUDE_DIRS})
        list(APPEND include_args -I ${include_dir})
    endforeach()

    set(${INCLUDE_DIR_ARGS} ${include_args} PARENT_SCOPE)
endfunction()

# Generate C++ from .proto files
function(protobuf_generate_cpp SRCS HDRS OUT_DIR)
    cmake_parse_arguments(PROTO "" "PROTO_ROOT" "" ${ARGN})

    if(NOT PROTO_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "protobuf_generate_cpp() called without proto files")
    endif()

    if(NOT PROTO_PROTO_ROOT)
        set(PROTO_PROTO_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    protoc_prepare_include_paths(protobuf_include_path ${PROTO_PROTO_ROOT} ${PROTO_UNPARSED_ARGUMENTS})

    set(generated_srcs)
    set(generated_hdrs)

    if(OUT_DIR)
        set(output_dir ${CMAKE_CURRENT_BINARY_DIR}/${OUT_DIR})
    else()
        set(output_dir ${CMAKE_CURRENT_BINARY_DIR})
    endif()

    foreach(proto_file ${PROTO_UNPARSED_ARGUMENTS})
        get_filename_component(abs_file ${proto_file} ABSOLUTE)
        get_filename_component(file_name ${proto_file} NAME_WE)
        get_filename_component(file_dir ${proto_file} DIRECTORY)

        set(proto_output_dir ${output_dir}/${file_dir})
        file(MAKE_DIRECTORY ${proto_output_dir})

        set(proto_base ${output_dir}/${file_dir}/${file_name})
        set(cpp_file ${proto_base}.pb.cc)
        set(header_file ${proto_base}.pb.h)

        list(APPEND generated_srcs ${cpp_file})
        list(APPEND generated_hdrs ${header_file})

        add_custom_command(
            OUTPUT ${cpp_file} ${header_file}
            COMMAND ${Protobuf_PROTOC_EXECUTABLE}
                --cpp_out=${output_dir}
                ${protobuf_include_path}
                ${abs_file}
            DEPENDS ${abs_file} ${Protobuf_PROTOC_EXECUTABLE}
            COMMENT "Generating C++ code from ${proto_file}"
            VERBATIM
        )
    endforeach()

    set_source_files_properties(${generated_srcs} ${generated_hdrs} PROPERTIES GENERATED TRUE)

    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
        set_source_files_properties(${generated_srcs} ${generated_hdrs}
            PROPERTIES COMPILE_FLAGS "-Wno-deprecated-declarations -Wno-unused-parameter"
        )
    endif()

    set(${SRCS} ${generated_srcs} PARENT_SCOPE)
    set(${HDRS} ${generated_hdrs} PARENT_SCOPE)
endfunction()

# Convenience: create a library from .proto files
function(add_proto_library TARGET_NAME)
    cmake_parse_arguments(PROTO "" "OUTPUT_DIR;PROTO_ROOT" "PROTOS" ${ARGN})

    if(NOT PROTO_PROTOS)
        message(FATAL_ERROR "add_proto_library requires PROTOS argument")
    endif()

    if(NOT PROTO_PROTO_ROOT)
        set(PROTO_PROTO_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    register_proto_files(PROTO_ROOT ${PROTO_PROTO_ROOT} PROTOS ${PROTO_PROTOS})

    protobuf_generate_cpp(proto_srcs proto_hdrs "${PROTO_OUTPUT_DIR}"
        PROTO_ROOT ${PROTO_PROTO_ROOT} ${PROTO_PROTOS})

    add_library(${TARGET_NAME} ${proto_srcs} ${proto_hdrs})
    target_link_libraries(${TARGET_NAME} PUBLIC protobuf::libprotobuf)
    target_include_directories(${TARGET_NAME} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
        $<INSTALL_INTERFACE:include>
    )
endfunction()
