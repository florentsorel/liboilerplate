# make                        build the library, the example and the tests
#                             (debug mode, with sanitizers)
# make run                    build and run the example
# make tests                  build and run all the tests
# make tests ARGS="-f add"    only the tests whose name contains "add"
# make tests ARGS="-l"        list the tests
# make MODE=release ...       optimized build, without sanitizers
# make clean

# Name of the library: the archive is build/<mode>/lib$(LIB).a, the public
# headers are in include/$(LIB)/ and every public name starts with $(LIB)_.
LIB = mylib

CC    = cc
MODE ?= debug

# -MMD -MP: alongside each .o, write a .d file listing the headers it
# includes, so that changing a header rebuilds the files that use it.
CFLAGS  = -std=c99 -Wall -Wextra -Wpedantic -Iinclude -MMD -MP
LDFLAGS =

# Stricter warnings, for our own code only: Unity is not written for them.
# Keep this list in sync with compile_flags.txt, which clangd reads.
# (-Wswitch and -Wreturn-type are already part of -Wall.)
WARNINGS = -Wshadow -Wconversion -Wsign-conversion -Wformat=2 \
           -Wstrict-prototypes -Wmissing-prototypes -Wcast-qual \
           -Wvla -Wimplicit-fallthrough

ifeq ($(MODE),debug)
# -fno-sanitize-recover: undefined behaviour stops the program instead of
# printing a warning that is easy to miss.
SANITIZERS = -fsanitize=address,undefined -fno-sanitize-recover=all
CFLAGS  += -g -O0 -fno-omit-frame-pointer $(SANITIZERS)
LDFLAGS += $(SANITIZERS)
else ifeq ($(MODE),release)
CFLAGS += -O2 -DNDEBUG
else
$(error MODE must be debug or release, not "$(MODE)")
endif

BUILD_DIR = build/$(MODE)
OBJ_DIR   = $(BUILD_DIR)/obj

# Every .c file is picked up: adding a module needs no change here.
LIB_SRC     = $(wildcard src/*.c)
EXAMPLE_SRC = $(wildcard examples/*.c)
TEST_SRC    = $(wildcard tests/*.c)

LIB_OBJ     = $(LIB_SRC:%.c=$(OBJ_DIR)/%.o)
EXAMPLE_OBJ = $(EXAMPLE_SRC:%.c=$(OBJ_DIR)/%.o)
TEST_OBJ    = $(TEST_SRC:%.c=$(OBJ_DIR)/%.o)

LIB_FILE    = $(BUILD_DIR)/lib$(LIB).a
EXAMPLE_BIN = $(BUILD_DIR)/example
TEST_BIN    = $(BUILD_DIR)/tests

# Unity is copied into vendor/unity. Its command-line options (-f, -x, -l)
# only exist when compiled with UNITY_USE_COMMAND_LINE_ARGS.
UNITY       = vendor/unity
UNITY_FLAGS = -I$(UNITY) -DUNITY_USE_COMMAND_LINE_ARGS -DUNITY_SUPPORT_64
UNITY_OBJ   = $(OBJ_DIR)/unity.o

all: $(LIB_FILE) $(EXAMPLE_BIN) $(TEST_BIN)

# The library: an archive of the object files (ar: r = add or replace,
# c = create, s = write an index so the linker finds symbols quickly).
$(LIB_FILE): $(LIB_OBJ)
	ar rcs $@ $^

# The example and the tests link against the archive, like any user would.
$(EXAMPLE_BIN): $(EXAMPLE_OBJ) $(LIB_FILE)
	$(CC) $(LDFLAGS) $^ -o $@

$(TEST_BIN): $(TEST_OBJ) $(UNITY_OBJ) $(LIB_FILE)
	$(CC) $(LDFLAGS) $^ -o $@

# -c: compile only, no link, which produces one object file (.o) per .c.
# $(@D) is the folder of the target: build/debug/obj/src, and so on.
$(OBJ_DIR)/src/%.o $(OBJ_DIR)/examples/%.o: CFLAGS += $(WARNINGS)
$(OBJ_DIR)/tests/%.o: CFLAGS += $(WARNINGS) $(UNITY_FLAGS)

$(OBJ_DIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

# Unity is compiled on its own, without $(WARNINGS).
$(UNITY_OBJ): $(UNITY)/unity.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(UNITY_FLAGS) -c $< -o $@

run: $(EXAMPLE_BIN)
	./$<

tests: $(TEST_BIN)
	./$< $(ARGS)

clean:
	rm -rf build

-include $(LIB_OBJ:.o=.d) $(EXAMPLE_OBJ:.o=.d) $(TEST_OBJ:.o=.d) $(UNITY_OBJ:.o=.d)

.PHONY: all run tests clean
