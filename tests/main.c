#include "tests.h"

bool tests_list_only = false;

// Unity calls setUp() before each test and tearDown() after it.
// Nothing to prepare here, but both must exist.
void setUp(void) {}

void tearDown(void) {}

int main(int argc, char *argv[]) {
    int options = UnityParseOptions(argc, argv);  // -1 means "-l"
    if (options > 0) {
        return 1;
    }
    tests_list_only = options < 0;

    UNITY_BEGIN();
    error_tests();
    example_tests();
    return tests_list_only ? 0 : UNITY_END();
}
