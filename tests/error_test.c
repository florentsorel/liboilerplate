#include <mylib/error.h>

#include "tests.h"

static void test_error_string_known_codes(void) {
    TEST_ASSERT_EQUAL_STRING("no error", mylib_error_string(MYLIB_OK));
    TEST_ASSERT_EQUAL_STRING("number too large",
                             mylib_error_string(MYLIB_ERR_OVERFLOW));
}

static void test_error_string_unknown_code(void) {
    // An enum is an int in C: a caller can pass a value that is not a code.
    TEST_ASSERT_EQUAL_STRING("unknown error", mylib_error_string((MylibError)42));
}

void error_tests(void) {
    RUN(test_error_string_known_codes);
    RUN(test_error_string_unknown_code);
}
