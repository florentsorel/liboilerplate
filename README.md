# C Library Boilerplate

A minimal starter for a C99 static library, with unit tests via
[Unity](https://github.com/ThrowTheSwitch/Unity), sanitizers in debug builds
and strict warnings.

## Project structure

```
.
├── include/mylib/     Public headers, included as <mylib/example.h>
│   └── example.h
├── src/               Library implementation, archived into libmylib.a
│   └── example.c
├── examples/          A program using the library, as its users would
│   └── main.c
├── tests/             Unit tests
│   ├── main.c         Test runner
│   ├── tests.h        RUN() macro and one suite function per module
│   └── example_test.c Tests of the example module
├── vendor/unity/      Unity, copied in (no download at build time)
├── compile_flags.txt  clangd / LSP config
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
3. Create `tests/parser_test.c` with `static` test functions and one public
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

4. Declare `void parser_tests(void);` in `tests/tests.h` and call
   `parser_tests();` in `tests/main.c`.

## Renaming the library

`mylib` appears in the folder `include/mylib/`, in the `LIB` variable of the
Makefile and in the `mylib_` / `MYLIB_` prefixes. To rename it to `foo`:

```sh
git mv include/mylib include/foo
grep -rlI --exclude-dir=.git --exclude-dir=vendor -e mylib -e MYLIB . \
  | xargs sed -i.bak -e 's/mylib/foo/g' -e 's/MYLIB/FOO/g'
find . -name '*.bak' -delete
```

(`sed -i.bak` works with both the macOS and the GNU `sed`.)

Then rename `example` to the real first module of your library.

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
