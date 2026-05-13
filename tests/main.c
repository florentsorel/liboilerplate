#include "example/example_test.h"
#include "unity/unity.h"

void setUp(void) {}

void tearDown(void) {}

int main(void) {
  UNITY_BEGIN();
  RUN_TEST(test_add);
  return UNITY_END();
}
