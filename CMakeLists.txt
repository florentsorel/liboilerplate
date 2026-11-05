# The usual commands are in CMakePresets.json:
#   cmake --workflow --preset debug     configure, build and test (sanitizers)
#   cmake --workflow --preset release   the same, optimized
# See the README for the details.

cmake_minimum_required(VERSION 3.25)

project(mylib VERSION 0.1.0 LANGUAGES C)

# ---------------------------------------------------------------------------
# Settings for every target, Unity included
# ---------------------------------------------------------------------------

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)  # -std=c99, not the GNU dialect -std=gnu99

# Writes build/compile_commands.json, which clangd finds on its own.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Only when this is the main project: a project that pulls in mylib chooses
# its own build type, and would fail to link a library built with sanitizers
# it does not use itself.
if(PROJECT_IS_TOP_LEVEL)
    # Without a build type, CMake compiles with neither -g nor -O.
    if(NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE Debug CACHE STRING "Debug or Release" FORCE)
    endif()

    # Debug: AddressSanitizer and UndefinedBehaviorSanitizer. With
    # -fno-sanitize-recover, undefined behaviour stops the program instead of
    # printing a warning that is easy to miss.
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(SANITIZERS -fsanitize=address,undefined -fno-sanitize-recover=all)
        add_compile_options(${SANITIZERS} -fno-omit-frame-pointer)
        add_link_options(${SANITIZERS})
    endif()
endif()

# Stricter warnings, for our own targets only: Unity has its own.
# (-Wswitch and -Wreturn-type are already part of -Wall.)
set(WARNINGS
    -Wall -Wextra -Wpedantic
    -Wshadow -Wconversion -Wsign-conversion -Wformat=2
    -Wstrict-prototypes -Wmissing-prototypes -Wcast-qual
    -Wvla -Wimplicit-fallthrough
)

# ---------------------------------------------------------------------------
# The library: build/libmylib.a
# ---------------------------------------------------------------------------

# Each new src/*.c file is added to this list.
add_library(mylib STATIC
    src/error.c
    src/example.c
)
# PUBLIC: the targets that link against mylib get include/ too, which is
# how examples/ and tests/ find <mylib/example.h>.
target_include_directories(mylib PUBLIC include)
target_compile_options(mylib PRIVATE ${WARNINGS})

# ---------------------------------------------------------------------------
# Example and tests, built only when this is the main project: a project
# that pulls in mylib with FetchContent or add_subdirectory does not
# download Unity.
# ---------------------------------------------------------------------------

option(MYLIB_BUILD_TESTS "Build the example and the tests" ${PROJECT_IS_TOP_LEVEL})

if(MYLIB_BUILD_TESTS)
    add_executable(example examples/main.c)
    target_link_libraries(example PRIVATE mylib)
    target_compile_options(example PRIVATE ${WARNINGS})

    # Unity is downloaded once per build folder, into build/_deps/. The build
    # stops if the archive does not match URL_HASH. To upgrade: change the
    # version in the URL, then the hash, given by
    #   curl -sL <url> | shasum -a 256
    include(FetchContent)
    FetchContent_Declare(unity
        URL https://github.com/ThrowTheSwitch/Unity/archive/refs/tags/v2.7.0.tar.gz
        URL_HASH SHA256=e84eb301ca7967831e68b1728f911e87fa2d345d8ddb64f897bc2f2ee24a321c
    )
    FetchContent_MakeAvailable(unity)

    # The -f, -x and -l options of the test runner, and 64-bit assertions.
    target_compile_definitions(unity PUBLIC
        UNITY_USE_COMMAND_LINE_ARGS
        UNITY_SUPPORT_64
    )

    # Each new tests/<module>_test.c file is added to this list.
    add_executable(tests
        tests/main.c
        tests/error_test.c
        tests/example_test.c
    )
    target_link_libraries(tests PRIVATE mylib unity::framework)
    # CMake compiles with absolute paths, which end up in __FILE__ and so in
    # every line Unity prints: report tests/example_test.c:13 instead.
    target_compile_options(tests PRIVATE ${WARNINGS}
        -fmacro-prefix-map=${PROJECT_SOURCE_DIR}/=
    )

    # ctest runs both programs: the tests, and the example as a smoke test.
    enable_testing()
    add_test(NAME tests COMMAND tests)
    add_test(NAME example COMMAND example)
endif()
