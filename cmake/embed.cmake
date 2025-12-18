cmake_policy(SET CMP0174 NEW)

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/data/mimes.txt" MIME_DATA)
string(REPLACE "\n" ";" MIME_LIST "${MIME_DATA}")

set(_EMBED_ROOT       "${CMAKE_CURRENT_SOURCE_DIR}"      CACHE PATH "Embed Root"  FORCE)
set(_EMBED_SCRIPT     "${_EMBED_ROOT}/cmake/embed.cmake" CACHE PATH "Script Path" FORCE)
set(_EMBED_DATA_DIR   "${_EMBED_ROOT}/data"              CACHE PATH "Data Path"   FORCE)
set(_EMBED_MIME_DATA  ${MIME_LIST}                       CACHE PATH "Mime Data"   FORCE)

function(embed_message LEVEL MESSAGE)
    message(${LEVEL} "embed: ${MESSAGE}")
endfunction()

function (embed_mime FILE OUTPUT)
    cmake_path(GET FILE EXTENSION LAST_ONLY FILE_EXTENSION)

    if (NOT FILE_EXTENSION)
        embed_message(WARNING "Could not determine extension for '${FILE}'")
        return()
    endif()

    # TODO: Make use of string(REGEX QUOTE) once CMake 4.2 is a realistic target
    string(SUBSTRING "${FILE_EXTENSION}" 1 -1 FILE_EXTENSION)

    set(MIME_DATA ${_EMBED_MIME_DATA})
    list(FILTER MIME_DATA INCLUDE REGEX "\\[${FILE_EXTENSION}\\]")

    if (NOT MIME_DATA)
        embed_message(WARNING "Could not determine mime for '${FILE}'")
        return()
    endif()

    list(POP_FRONT MIME_DATA MIME_MATCH)
    string(REGEX MATCH "(.*):" _ "${MIME_MATCH}")

    if (NOT CMAKE_MATCH_1)
        embed_message(WARNING "Could not extract mime from '${MIME_MATCH}' (${FILE})")
        return()
    endif()

    set(${OUTPUT} "${CMAKE_MATCH_1}" PARENT_SCOPE)
endfunction()

function(embed_read FILE OUTPUT)
    file(READ "${FILE}" FILE_HEX HEX)
    file(SIZE "${FILE}" FILE_SIZE)

    string(REGEX MATCHALL "([A-Za-z0-9][A-Za-z0-9])" FILE_SPLIT "${FILE_HEX}")
    list(JOIN FILE_SPLIT ", 0x" FILE_CONTENT)
    string(PREPEND FILE_CONTENT "0x")

    set(${OUTPUT}_SIZE    "${FILE_SIZE}"    PARENT_SCOPE)
    set(${OUTPUT}_CONTENT "${FILE_CONTENT}" PARENT_SCOPE)
endfunction()

function(embed_generate OUTPUT)
    cmake_parse_arguments(PARSE_ARGV 1 generate "" "FILE;ROOT;SIZE;CONTENT;IDENTIFIER;DESTINATION" "")

    set(RELATIVE "${generate_FILE}")
    cmake_path(RELATIVE_PATH RELATIVE BASE_DIRECTORY "${generate_ROOT}")

    set(HEADER "${generate_DESTINATION}")
    cmake_path(APPEND HEADER "${RELATIVE}.hpp")

    set(SOURCE "${generate_DESTINATION}")
    cmake_path(APPEND SOURCE "${RELATIVE}.cpp")

    embed_read("${generate_FILE}" FILE)

    set(SIZE       "${FILE_SIZE}")
    set(CONTENT    "${FILE_CONTENT}")
    set(IDENTIFIER "${generate_IDENTIFIER}")

    cmake_path(GET HEADER FILENAME INCLUDE)

    configure_file("${_EMBED_DATA_DIR}/embed.file.cpp.in" "${SOURCE}")
    configure_file("${_EMBED_DATA_DIR}/embed.file.hpp.in" "${HEADER}")

    set(${OUTPUT}_HEADER "${HEADER}"    PARENT_SCOPE)
    set(${OUTPUT}_PATH   "/${RELATIVE}" PARENT_SCOPE)
endfunction()

function(embed_target NAME DIRECTORY)
    set(TARGET "saucer_${NAME}")

    set(GLOB "${DIRECTORY}")
    cmake_path(APPEND GLOB "*.cpp")
    file(GLOB_RECURSE SOURCES ${GLOB})

    add_library(${TARGET} STATIC)
    add_library("saucer::${NAME}" ALIAS ${TARGET})

    target_sources(${TARGET} PRIVATE ${SOURCES})
    target_include_directories(${TARGET} PUBLIC "${DIRECTORY}")

    target_compile_features(${TARGET} PUBLIC cxx_std_23)
    set_target_properties(${TARGET} PROPERTIES CXX_STANDARD 23 CXX_EXTENSIONS OFF CXX_STANDARD_REQUIRED ON)
endfunction()

function(saucer_embed DIRECTORY)
    cmake_parse_arguments(PARSE_ARGV 1 embed "" "NAME;DESTINATION;TARGET" "")

    if (NOT embed_DESTINATION)
        set(embed_DESTINATION "embedded")
    endif()

    if (NOT embed_NAME)
        set(embed_NAME "embedded")
    endif()

    cmake_path(ABSOLUTE_PATH DIRECTORY)

    set(GLOB "${DIRECTORY}")
    cmake_path(APPEND GLOB "*")
    file(GLOB_RECURSE FILES ${GLOB})

    set(output_ROOT "${embed_DESTINATION}")
    cmake_path(ABSOLUTE_PATH output_ROOT)

    set(output_HEADERS "${output_ROOT}")
    cmake_path(APPEND output_HEADERS "saucer" "embedded")

    set(output_FILES "${output_HEADERS}")
    cmake_path(APPEND output_FILES "files")

    set(generated_INCLUDES "")
    set(generated_EMBEDDED "")

    foreach(path IN LISTS FILES)
        embed_message(STATUS "Embedding ${path}")

        cmake_path(HASH path embedded_HASH)
        string(MAKE_C_IDENTIFIER "${embedded_HASH}" embedded_NAME)

        embed_generate(embedded
            FILE        "${path}"
            ROOT        "${DIRECTORY}"
            IDENTIFIER  "${embedded_NAME}"
            DESTINATION "${output_FILES}"
        )

        cmake_path(RELATIVE_PATH embedded_HEADER BASE_DIRECTORY "${output_HEADERS}")
        list(APPEND generated_INCLUDES "#include \"${embedded_HEADER}\"")

        embed_mime("${path}" embedded_MIME)
        list(APPEND generated_EMBEDDED "{\"${embedded_PATH}\", saucer::embedded_file{.content = saucer::stash<>::view(${embedded_NAME}), .mime = \"${embedded_MIME}\"}}")
    endforeach()

    set(meta_FILE "${output_HEADERS}")
    cmake_path(APPEND meta_FILE "all.hpp")

    list(JOIN generated_INCLUDES "\n"        INCLUDES)
    list(JOIN generated_EMBEDDED ",\n\t\t\t" FILES)

    configure_file("${_EMBED_DATA_DIR}/embed.hpp.in" "${meta_FILE}")

    if (CMAKE_SCRIPT_MODE_FILE)
        return()
    endif()

    embed_target(${embed_NAME} "${output_ROOT}")

    if (NOT embed_TARGET)
        return()
    endif()

    set(PRE_TARGET "saucer_${embed_NAME}_pre")

    add_custom_target(${PRE_TARGET}
        COMMAND           "${CMAKE_COMMAND} -P ${_EMBED_SCRIPT} ${DIRECTORY} ${output_ROOT}"
        WORKING_DIRECTORY "${_EMBED_ROOT}"
    )

    add_dependencies(${embed_TARGET} ${PRE_TARGET})
endfunction()

if (NOT CMAKE_SCRIPT_MODE_FILE)
    return()
endif()

if (CMAKE_ARGC LESS 4)
    embed_message(FATAL_ERROR "Usage: embed <directory> [destination]")
endif()

saucer_embed("${CMAKE_ARGV3}" DESTINATION "${CMAKE_ARGV4}")
