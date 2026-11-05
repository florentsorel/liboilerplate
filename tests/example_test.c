#include <mylib/example.h>

#include "tests.h"

// The tests are static: only example_tests() below needs to see them, so
// they need no declaration in a header.

// ----------------------------------------------------------------------------
// mylib_add
// ----------------------------------------------------------------------------

static void test_add_positive(void) {
    TEST_ASSERT_EQUAL_INT(5, mylib_add(3, 2));
}

static void test_add_opposites_cancel_out(void) {
    TEST_ASSERT_EQUAL_INT(0, mylib_add(-1, 1));
}

// ----------------------------------------------------------------------------
// mylib_parse_number
// ----------------------------------------------------------------------------

// Macros rather than functions, so that a failure reports the line of the
// test, not the line of a helper. do { ... } while (0) makes the macro a
// single statement, which also works after an if without braces.

// Parses text and checks that it succeeds with the expected value.
#define ASSERT_PARSES(expected_value, text)                                \
    do {                                                                   \
        int out = -1;                                                      \
        TEST_ASSERT_EQUAL_INT(MYLIB_OK, mylib_parse_number((text), &out)); \
        TEST_ASSERT_EQUAL_INT((expected_value), out);                      \
    } while (0)

// Parses text and checks that it fails with the expected code, leaving the
// out parameter untouched (see the convention in mylib/error.h).
#define ASSERT_PARSE_FAILS(expected_error, text)                         \
    do {                                                                 \
        int out = -1;                                                    \
        TEST_ASSERT_EQUAL_INT((expected_error),                          \
                              mylib_parse_number((text), &out));         \
        TEST_ASSERT_EQUAL_INT_MESSAGE(-1, out, "out written on failure"); \
    } while (0)

static void test_parse_number_valid(void) {
    ASSERT_PARSES(0, "0");
    ASSERT_PARSES(42, "42");
    ASSERT_PARSES(7, "007");
}

static void test_parse_number_largest(void) {
    // INT_MAX with a 32-bit int, the case on every platform the CI runs on.
    ASSERT_PARSES(2147483647, "2147483647");
}

static void test_parse_number_empty(void) {
    ASSERT_PARSE_FAILS(MYLIB_ERR_EMPTY, "");
}

static void test_parse_number_not_a_number(void) {
    ASSERT_PARSE_FAILS(MYLIB_ERR_NOT_A_NUMBER, "4x2");
    ASSERT_PARSE_FAILS(MYLIB_ERR_NOT_A_NUMBER, "-1");
    ASSERT_PARSE_FAILS(MYLIB_ERR_NOT_A_NUMBER, "+1");
    ASSERT_PARSE_FAILS(MYLIB_ERR_NOT_A_NUMBER, " 42");
    ASSERT_PARSE_FAILS(MYLIB_ERR_NOT_A_NUMBER, "42\n");
}

static void test_parse_number_overflow(void) {
    ASSERT_PARSE_FAILS(MYLIB_ERR_OVERFLOW, "2147483648");  // INT_MAX + 1
    ASSERT_PARSE_FAILS(MYLIB_ERR_OVERFLOW, "99999999999999999999");
}

void example_tests(void) {
    RUN(test_add_positive);
    RUN(test_add_opposites_cancel_out);
    RUN(test_parse_number_valid);
    RUN(test_parse_number_largest);
    RUN(test_parse_number_empty);
    RUN(test_parse_number_not_a_number);
    RUN(test_parse_number_overflow);
}
