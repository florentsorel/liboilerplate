# C Library Boilerplate

A minimal starter for a C99 static library built with CMake, with unit tests
via [Unity](https://github.com/ThrowTheSwitch/Unity), sanitizers in debug
builds and strict warnings.

Requires CMake 3.25 or later and a C compiler (clang or gcc).

## Project structure

```
.
├── include/mylib/     Public headers, included as <mylib/example.h>
│   ├── error.h        Error codes shared by the whole library
│   └── example.h
├── src/               Library implementation, archived into libmylib.a
│   ├── error.c
│   └── example.c
├── examples/          A program using the library, as its users would
│   └── main.c
├── tests/             Unit tests
│   ├── main.c         Test runner
│   ├── tests.h        RUN() macro and one suite function per module
│   ├── error_test.c   Tests of the error module
│   └── example_test.c Tests of the example module
├── CMakeLists.txt     What to build: the library, the example, the tests
├── CMakePresets.json  How to build it: debug and release
├── rename.sh          Renames mylib, then deletes itself
└── .github/workflows/ CI on Linux (gcc) and macOS (clang)
```

## Building

```sh
cmake --workflow --preset debug     # configure, build, run the tests
```

Two presets, each with its own build folder:

| Preset    | Folder           | Flags                                                |
| --------- | ---------------- | ---------------------------------------------------- |
| `debug`   | `build/`         | `-g`, AddressSanitizer, UndefinedBehaviorSanitizer   |
| `release` | `build-release/` | `-O3 -DNDEBUG`, no sanitizers                        |

In debug, the sanitizers stop the program on the first out-of-bounds access
or undefined behaviour.

`--workflow` chains the three steps, which can also be run one by one:

| Command                            | What it does                                   |
| ---------------------------------- | ---------------------------------------------- |
| `cmake --preset debug`             | Configure: generate `build/`, download Unity   |
| `cmake --build --preset debug`     | Build what changed                             |
| `ctest --preset debug`             | Run the tests and the example                  |
| `cmake --build --preset debug -v`  | Build, showing the full compiler commands      |
| `rm -rf build`                     | Start from scratch                             |

Configuring is needed once per folder; after that, `cmake --build` notices
on its own when `CMakeLists.txt` changes. Only the files that changed are
recompiled, including when a header they include changes.

The programs are in the build folder:

| File               | What it is                                            |
| ------------------ | ----------------------------------------------------- |
| `build/libmylib.a` | The library                                           |
| `build/example`    | The example program, linked against the library       |
| `build/tests`      | The test runner, linked against the library and Unity |

`ctest` only says whether the runner passed; run it directly to choose the
tests, or to use it in a debugger:

```sh
./build/tests              # every test, one line each
./build/tests -f parse     # only the tests whose name contains "parse"
./build/tests -x parse     # all but those
./build/tests -l           # list the tests
```

## Adding a module

Say the module is called `parser`:

1. Create `include/mylib/parser.h` and `src/parser.c`, and add
   `src/parser.c` to `add_library(mylib ...)` in `CMakeLists.txt`.
2. Prefix every public name with `mylib_` (`mylib_parse`, `MylibParser`...):
   C has no namespaces, so this keeps the names of the library from colliding
   with those of the program that uses it. Helpers used only inside a `.c`
   file should be `static`.
3. Functions that can fail return a `MylibError` and give their result
   through an out parameter, written only on success: see
   `mylib_parse_number`. Add new codes to `include/mylib/error.h` and to the
   `switch` of `src/error.c`; the compiler warns if one is missing.
4. Create `tests/parser_test.c` with `static` test functions and one public
   function that runs them:

   ```c
   #include <mylib/parser.h>

   #include "tests.h"

   static void test_parse_empty(void) {
       TEST_ASSERT_EQUAL_INT(0, mylib_parse(""));
   }

   void parser_tests(void) {
       RUN(test_parse_empty);
   }
   ```

5. Add `tests/parser_test.c` to `add_executable(tests ...)` in
   `CMakeLists.txt`, declare `void parser_tests(void);` in `tests/tests.h` and
   call `parser_tests();` in `tests/main.c`.

CMake wants the files listed by hand: with a pattern such as `src/*.c`, it
would not notice a new file until configured again.

### Assertion macros

When many tests call the same function and check the same things, write a
macro next to them rather than a helper function, like `ASSERT_PARSES` and
`ASSERT_PARSE_FAILS` in `tests/example_test.c`: Unity reports a failure at the
line where the assertion is written, so in a helper every failure would point
to the helper, while in a macro it points to the test.

```c
#define ASSERT_PARSE_FAILS(expected_error, text)                         \
    do {                                                                 \
        int out = -1;                                                    \
        TEST_ASSERT_EQUAL_INT((expected_error),                          \
                              mylib_parse_number((text), &out));         \
        TEST_ASSERT_EQUAL_INT_MESSAGE(-1, out, "out written on failure"); \
    } while (0)

ASSERT_PARSE_FAILS(MYLIB_ERR_NOT_A_NUMBER, "4x2");
```

`do { ... } while (0)` turns the body into a single statement, so the macro
behaves like a function call, even after an `if` without braces.

## Unity

Unity is not in the repository: CMake downloads the release named in
`CMakeLists.txt` the first time it configures a build folder, into
`build/_deps/`. The build stops if the archive does not match its SHA-256,
`URL_HASH`: what is compiled is always the code that was chosen. Configuring
a new build folder needs the network; building does not.

To upgrade, change the version in the URL, then `URL_HASH`, given by:

```sh
curl -sL https://github.com/ThrowTheSwitch/Unity/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
```

Unity is compiled with its own options, without the strict warnings of the
project, which it is not written for.

The example and the tests are only built when the library is the main
project (`MYLIB_BUILD_TESTS`): a project that pulls the library in with
`FetchContent` or `add_subdirectory` gets the library alone, without
downloading Unity.

## LSP

CMake writes `build/compile_commands.json`, with the exact flags of every
file. clangd finds it on its own once `cmake --preset debug` has run.

## Using as a template

On GitHub, mark this repo as a *Template repository* in the settings. New
projects get a clean copy without inheriting the git history.

<!-- rename:start -->
### Renaming the library

The library is called `mylib`: in `include/mylib/`, in `CMakeLists.txt` and
in the `mylib_` / `Mylib` / `MYLIB_` prefixes. In a new project, give it its
real name, here `foo`:

```sh
./rename.sh foo
rm -rf build build-release
cmake --workflow --preset debug
git commit -am "Rename the library to foo"
```

The script replaces `mylib`, `Mylib` and `MYLIB` everywhere except in the
build folders (`my_parser` gives `my_parser_`, `MyParser` and `MY_PARSER_`),
and moves `include/mylib/` to `include/foo/`. Then it
deletes itself and this section of the README, which are no longer needed. In
a git repository, it refuses to run with uncommitted changes, so that the
rename can be reviewed with `git diff` and undone with `git checkout`.
<!-- rename:end -->

Then rename `example` to the real first module of your library.
