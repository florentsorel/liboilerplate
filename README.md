# C Library Boilerplate

A minimal starter for a C99 static library, with unit tests via
[Unity](https://github.com/ThrowTheSwitch/Unity), sanitizers in debug builds
and strict warnings.

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
├── vendor/unity/      Unity, copied in (no download at build time)
├── compile_flags.txt  clangd / LSP config
├── rename.sh          Renames mylib, then deletes itself
└── Makefile
```

Everything is built into `build/<mode>/`:

| File                   | What it is                                   |
| ---------------------- | -------------------------------------------- |
| `libmylib.a`           | The library                                  |
| `example`              | The example program, linked against the .a   |
| `tests`                | The test runner, linked against the .a       |
| `obj/`                 | Object files, and .d files listing headers   |

## Make targets

| Command                     | What it does                                       |
| --------------------------- | -------------------------------------------------- |
| `make`                      | Build the library, the example and the tests       |
| `make run`                  | Build and run the example                          |
| `make tests`                | Build and run all the tests                        |
| `make tests ARGS="-f add"`  | Only the tests whose name contains `add`           |
| `make tests ARGS="-x add"`  | Skip the tests whose name contains `add`           |
| `make tests ARGS="-l"`      | List the tests                                     |
| `make MODE=release ...`     | Optimized build, without sanitizers                |
| `make clean`                | Delete `build/`                                    |

The default mode is `debug`: `-g -O0` with AddressSanitizer and
UndefinedBehaviorSanitizer, which stop the program on the first out-of-bounds
access or undefined behaviour. Use the debug binaries in a debugger:
`build/debug/tests` and `build/debug/example`.

Only files that changed are recompiled, including when a header they include
changes.

## Adding a module

Say the module is called `parser`:

1. Create `include/mylib/parser.h` and `src/parser.c`. The Makefile picks up
   every `src/*.c` file, so there is nothing to add there.
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

5. Declare `void parser_tests(void);` in `tests/tests.h` and call
   `parser_tests();` in `tests/main.c`.

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

Unity's three files and its license are copied into `vendor/unity/`: the
build needs no network and always uses the same version. To upgrade, replace
them with the files from `src/` of a
[Unity release](https://github.com/ThrowTheSwitch/Unity/releases).

Unity is compiled on its own, without the strict warnings of the project,
which it is not written for.

## LSP

`compile_flags.txt` tells clangd which include paths and flags to use. Keep it
in sync with the Makefile when you add `-I` paths or warnings.

## Using as a template

On GitHub, mark this repo as a *Template repository* in the settings. New
projects get a clean copy without inheriting the git history.

<!-- rename:start -->
### Renaming the library

The library is called `mylib`: in `include/mylib/`, in the `LIB` variable of
the Makefile and in the `mylib_` / `MYLIB_` prefixes. In a new project, give it
its real name, here `foo`:

```sh
./rename.sh foo
make clean tests
git commit -am "Rename the library to foo"
```

The script replaces `mylib`, `Mylib` and `MYLIB` everywhere except in
`vendor/` and `build/`, and moves `include/mylib/` to `include/foo/`. Then it
deletes itself and this section of the README, which are no longer needed. In
a git repository, it refuses to run with uncommitted changes, so that the
rename can be reviewed with `git diff` and undone with `git checkout`.
<!-- rename:end -->

Then rename `example` to the real first module of your library.
