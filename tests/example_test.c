#include <mylib/example.h>

#include "tests.h"

// The tests are static: only example_tests() below needs to see them, so
// they need no declaration in a header.

static void test_add_positive(void) {
    TEST_ASSERT_EQUAL_INT(5, mylib_add(3, 2));
}

static void test_add_opposites_cancel_out(void) {
    TEST_ASSERT_EQUAL_INT(0, mylib_add(-1, 1));
}

void example_tests(void) {
    RUN(test_add_positive);
    RUN(test_add_opposites_cancel_out);
}
