CC=gcc
CFLAGS=-Wall -Wextra -Wpedantic -std=c99 -ggdb -Iinclude
LIBS=
UNITY_VERSION=2.6.1

SRC=src/main.c lib/example.c
SRC_TEST=tests/main.c tests/unity/unity.c lib/example.c tests/example/example_test.c

build:
	@mkdir -p build
	@$(CC) $(CFLAGS) -o build/main $(SRC) $(LIBS)

run: build
	@./build/main

build_test: tests/unity/unity.c
	@mkdir -p build
	@$(CC) $(CFLAGS) -Itests -o build/test $(SRC_TEST) $(LIBS)

test: build_test
	@./build/test

tests/unity/unity.c:
	@mkdir -p tests/unity
	@echo "Downloading Unity Test Framework v$(UNITY_VERSION)..."
	@curl -sL -o unity.tar.gz https://github.com/ThrowTheSwitch/Unity/archive/refs/tags/v$(UNITY_VERSION).tar.gz
	@tar -xzf unity.tar.gz
	@rm unity.tar.gz
	@mv Unity-$(UNITY_VERSION)/src/unity_internals.h tests/unity/
	@mv Unity-$(UNITY_VERSION)/src/unity.h tests/unity/
	@mv Unity-$(UNITY_VERSION)/src/unity.c tests/unity/
	@rm -rf Unity-$(UNITY_VERSION)
	@echo "Unity Test Framework downloaded and extracted."

.PHONY: build run test build_test
