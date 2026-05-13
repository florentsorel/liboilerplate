# C Library Boilerplate

A minimal starter for a C library with unit tests via [Unity](https://github.com/ThrowTheSwitch/Unity).

## Project structure

```
.
├── include/         Public headers (consumed by users of the lib)
│   └── example.h
├── lib/             Library implementation
│   └── example.c
├── src/             Demo executable
│   └── main.c
├── tests/           Unit tests
│   ├── main.c       Test runner
│   ├── example/     One folder per module under test
│   │   ├── example_test.h
│   │   └── example_test.c
│   └── unity/       Auto-downloaded on first `make test`
├── compile_flags.txt  clangd / LSP config
└── Makefile
```

## Make targets

| Target       | What it does                                                  |
| ------------ | ------------------------------------------------------------- |
| `make build` | Compile the demo binary into `build/main`                     |
| `make run`   | Build and run the demo                                        |
| `make test`  | Download Unity (first run only), build and run the test suite |

Unity is fetched from GitHub the first time `make test` runs and cached in `tests/unity/`. To upgrade, bump `UNITY_VERSION` in the Makefile and `rm -rf tests/unity` before the next build.

## Adding a new module

1. Create `include/<module>.h` and `lib/<module>.c`.
2. Add `lib/<module>.c` to `SRC` in the Makefile.
3. Create `tests/<module>/<module>_test.h` + `tests/<module>/<module>_test.c`.
4. Add `tests/<module>/<module>_test.c` to `SRC_TEST`.
5. In `tests/main.c`, `#include "<module>/<module>_test.h"` and add `RUN_TEST(test_<name>);` calls inside `main()`.

## LSP

`compile_flags.txt` at the root tells clangd which include paths and flags to use. Adjust if you add more `-I` entries to the Makefile.

## Using as a template

On GitHub, mark this repo as a *Template repository* in the settings. New projects get a clean copy without inheriting the git history.

After cloning a copy, rename `example` to the real first module of your library.
