#include "example_test.h"
#include "example.h"
#include "unity/unity.h"

void test_add(void) {
  int sut = add(3, 2);
  TEST_ASSERT_EQUAL_INT(5, sut);

  int sut2 = add(-1, 1);
  TEST_ASSERT_EQUAL_INT(0, sut2);
}
