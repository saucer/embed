cmake_minimum_required(VERSION 3.25)
project(embed LANGUAGES CXX VERSION 1.0.0)

# --------------------------------------------------------------------------------------------------------
# Library switches
# --------------------------------------------------------------------------------------------------------

option(embed_parser "Build the mime-list parser" OFF)

# --------------------------------------------------------------------------------------------------------
# Setup Scripts
# --------------------------------------------------------------------------------------------------------

include("cmake/embed.cmake")

# --------------------------------------------------------------------------------------------------------
# Setup Library
# --------------------------------------------------------------------------------------------------------

if (NOT embed_parser)
  return()
endif()

add_executable(${PROJECT_NAME} "src/main.cpp")

target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_23)
set_target_properties(${PROJECT_NAME} PROPERTIES CXX_STANDARD 23 CXX_EXTENSIONS OFF CXX_STANDARD_REQUIRED ON)

if (PROJECT_IS_TOP_LEVEL AND NOT CMAKE_CXX_COMPILER_FRONTEND_VARIANT MATCHES "MSVC")
  target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -Wpedantic -Werror -pedantic -pedantic-errors -Wfatal-errors)
endif()

# --------------------------------------------------------------------------------------------------------
# Setup Dependencies
# --------------------------------------------------------------------------------------------------------

include("cmake/cpm.cmake")

CPMFindPackage(
  NAME           glaze
  VERSION        6.0.1
  GIT_REPOSITORY "https://github.com/stephenberry/glaze"
)

target_link_libraries(${PROJECT_NAME} PUBLIC glaze::glaze)
