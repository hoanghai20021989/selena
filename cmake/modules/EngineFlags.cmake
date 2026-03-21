# Shared compiler warnings
add_compile_options(
    -Werror
    -Wall
    -Wparentheses
    -Wnull-dereference
    -Wdangling-else
    -Wpessimizing-move
    -Wnon-virtual-dtor
    -Wno-deprecated-declarations
)

if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    add_compile_options(
        -Werror=unused-result
        -Wno-unknown-warning-option
        -Wno-missing-field-initializers
        -fno-ms-extensions
        -ggdb
        # -gz=zlib  # Requires newer ld for compressed debug sections
    )

    if(DEFINED ENV{TIME_TRACE})
        message(STATUS "Clang time-trace enabled")
        add_compile_options(-ftime-trace)
    endif()

    if(DEFINED ENV{CLANG_TIDY})
        set(CMAKE_CXX_CLANG_TIDY
            $ENV{CLANG_TIDY};
            -header-filter=.*![ext|pb\.h];
        )
    endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options(
        -Wno-error=class-memaccess
        -Wno-null-dereference
        -Wduplicated-cond
        -ggdb
        # -gz=zlib  # Requires newer ld for compressed debug sections
        -Wno-comment
    )
endif()
