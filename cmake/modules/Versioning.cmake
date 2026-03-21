function(extract_version_from_git)
    find_package(Git QUIET)

    if(NOT GIT_FOUND)
        message(WARNING "Git not found, version information will be unavailable")
        set(PROJECT_VERSION "unknown" PARENT_SCOPE)
        return()
    endif()

    execute_process(
        COMMAND ${GIT_EXECUTABLE} describe --tags --abbrev=0
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_TAG
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )

    if(NOT GIT_TAG)
        message(WARNING "No git tags found, version information will be unavailable")
        set(PROJECT_VERSION "unknown" PARENT_SCOPE)
        return()
    endif()

    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )

    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-list -n 1 ${GIT_TAG}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE TAG_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )

    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --short ${TAG_HASH}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE TAG_HASH_SHORT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )

    if(GIT_HASH STREQUAL TAG_HASH_SHORT)
        set(PROJECT_VERSION "${GIT_TAG}" PARENT_SCOPE)
        message(STATUS "Building release version: ${GIT_TAG}")
    else()
        set(PROJECT_VERSION "${GIT_TAG} (${GIT_HASH})" PARENT_SCOPE)
        message(STATUS "Building development version: ${GIT_TAG} (${GIT_HASH})")
    endif()
endfunction()
